#!/usr/local/bin/perl -wc

=head1 NAME

RepFormat	- Allows text formatting with simple instructions, mapping to a user-defined grid (the sheet).

=head1 SYNOPSIS

	use Data::Reporter::RepFormat;

	$sheet = new RepFormat($cols, $rows);
	$sheet->Move(0,3);
	$sheet->Print('123');
	$sheet->Out();
	$sheet->Clear();
	$sheet->Printf('%010d', 12);
	$sheet->MVPrint(0, 3, '123');
	$sheet->MVPrintf(0, 1, '%3.2f', 79.123);
	$sheet->Nlines();
	$sheet->Getline(20);
	$sheet->Copy($source_sheet);
	$sheet->Center('hello', 10);
	$value = $sheet->Commify('1234567.89');

=head1 DESCRIPTION

=item new($cols, $rows)

Creates a new RepFormat object. This function receives two parameters: columms and rows of the sheet.

=item $sheet->Move($col, $row)

Moves cursor to the indicated position

=item $sheet->Print($string)

Puts $string at the current cursor position.

=item $sheet->Out([$handle])

Moves the sheet information to target output. If $handle is not specified, then STDOUT is used.

=item $sheet->Clear()

Clears the sheet

=item $sheet->Printf(format, argument)

Prints using printf style format

=item $sheet->MVPrint($col, $row, $string)

Moves, then Prints

=item $sheet->MVPrintf($col, $row, format, argument)

Moves, then Prints (using printf style format)

=item $sheet->Nlines()

Returns the number of lines in the sheet, discarding the last blank lines

=item $sheet->Getline($index)

Returns the $index row 

=item $sheet->Copy($source_sheet)

Appends $source_sheet in $sheet

=item $sheet->Center($string, $size)

Returns a string with size = $size having $string centered in it. This function uses spaces to pad on both sides.

=item $sheet->Commify($number);

Returns $number as a string with commas (123456789.90 -> 123,456,789.90)

=cut

package RepFormat;
use strict;
use Carp;

sub new($$$) {
	my $class = shift;
	my $self = {};

	bless $self, $class;
	$self->{NUMCOL} = shift;
	$self->{NUMREN} = shift;
	$self->Clear();

	return $self;
}

sub Clear($) {
	my $self = shift;

	$self->{X} = 0;
	$self->{Y} = 0;
	$self->{MATRIZ} = [];
	my $arrayref = $self->{MATRIZ};
	my $i = 0;
	for($i = 0; $i < $self->{NUMREN}; $i++) {
		push @$arrayref, ' ' x $self->{NUMCOL};
	}
}

sub Out($;$) {
	my $self = shift;
	my $handle;

	if (@_ > 0) {
		$handle = shift;
	}
	else {
		$handle = select;
	}

	my $arrayref = $self->{MATRIZ};
	my $i;
	foreach $i ( @$arrayref ) {
		print $handle substr($i, 0, $self->{NUMCOL}),"\n";
	}
}

sub Move($$$) {
	my $self = shift;
	my $x = shift;
	my $y = shift;
	$self->{X} = $x if $x >= 0 && $x < $self->{NUMCOL};
	$self->{Y} = $y if $y >= 0 && $y < $self->{NUMREN};
}

sub MVPrintf($$$$@) {
	my $self = shift;
	my $x = shift;
	my $y = shift;
	my $formato = shift;

	$self->Move($x, $y);
	$self->Printf($formato, @_);
}

sub MVPrint($$$$) {
	my $self = shift;
	my ($x, $y, $str) = @_;

	$self->Move($x, $y);
	$self->Print($str);
}

sub Commify($$) {
	my $self = shift;
	my $str = shift;
	croak "Incorrect format ($str) to put commas"
   			if ($str !~ /([+-]{0,1})(\d+)(\.{0,1})(\d*)/);
	my $sign = "";
	$sign = $1 if (defined($1));
	my $integerpart = $2;
	my $decimalpart = "";
	$decimalpart = "\.$4" if ($4 ne "");
	my $size = length($str);

	$integerpart = reverse $integerpart;
	$str = "";
	while ($integerpart ne "") {
		if (length($integerpart) > 3) {
			$str .= substr($integerpart, 0, 3);
			$str .= ",";
			substr($integerpart, 0, 3) = "";
		} else {
			$str .= substr($integerpart, 0, length($integerpart));
			$integerpart = "";
		}
	}

	$str = $sign . (reverse $str) . $decimalpart;
	my $espaces = "";
	$espaces = " " x ($size - length($str)) if ($size >= length($str));
	$str = $espaces . $str;
	return $str;
}

sub Printf($$$) {
	my $self = shift;
	my $formato = shift;
	my $str = sprintf($formato, shift);
	$self->Print($str);
}

sub Print($$) {
	my $self = shift;
	my $str = shift;

	my $x = $self->{X};
	my $y = $self->{Y};

	my $ren = $self->{MATRIZ}->[$y];
	substr($ren, $x, length($str)) =  $str;

	$x += length($str);

	$self->{MATRIZ}->[$y] = $ren;
	$self->{X} = $x;
}

sub Center($$$) {
	use integer;
	my $self = shift;
	my $str = shift;
	my $len = shift;

	my $ini = ($len - length($str))/2;
	$str = " " x $ini . $str;
	return $str;
}

sub Getline($$) {
	my $self = shift;
	my $ren = shift;
	my $line = "";
	$line = $self->{MATRIZ}->[$ren] if ($ren >= 0 && $ren < $self->{NUMREN});
	$line;
}

sub Nlines($) {
	my $self = shift;
	my $lines = $self->{NUMREN}-1;
	my $espa = ' ' x $self->{NUMCOL};
	while ($lines >= 0 && $self->{MATRIZ}->[$lines] eq $espa) {
		$lines--;
	}
	$lines+1;
}

sub Copy($$) {
	my $self = shift;
	my $formato = shift;
	my $mynalines = $self->Nlines();
	my $nalines = $formato->Nlines();
	my $aux = 0;
	while ($aux < $nalines) {
		$self->MVPrint(0,$mynalines+$aux,$formato->Getline($aux));
		$aux++;
	}
}
1;
