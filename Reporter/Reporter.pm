#!/usr/local/bin/perl -wc
# %A%

=head1 NAME

Reporter - Report generator.

=head1 SYNOPSIS

 use strict;
 use Data::Reporter::RepFormat;
 use Data::Reporter::Reporter;
 use Data::Reporter::Filesource;

 sub HEADER($$$$) {
    my ($reporter, $sheet, $rep_actline, $rep_lastline) = @_;	
    $sheet->MVPrint(10,0, 'This is the header');
    $sheet->MVPrint(10,1, 'This is the page :');
    $sheet->Print($reporter->page());
 }

 sub TITLE($$$$) {
    my ($reporter, $sheet, $rep_actline, $rep_lastline) = @_;	
    $sheet->MVPrint(10,0, 'This is the title');
 }

 sub DETAIL($$$$) {
    my ($reporter, $sheet, $rep_actline, $rep_lastline) = @_;	
    $sheet->MVPrint(10,0, 'This is the detail');
    $sheet->MVPrint(10,1, 'This is the begin of the report') if ($reporter->{BOR});
 }

 #main
 {
    $source = new Filesource(File => "inputfile");
    my $report = new Reporter();
    $report->configure(
        Width => 105,
        Height => 66,
        SubHeaher => \&HEADER,
        SubTitle => \&TITLE,
        SubDetail => \&DETAIL,
        Source => $source,
        File_name => "OUPUT"
    );
    $report->generate();
 }

=head1 DESCRIPTION

=item Data::Reporter::new();

Creates a new Report handler

=item $report->configure(option => value)

=over 4

valid options are:

=item

Width		number of columns

=item

Height		number of rows

=item

Orientation 	Report orientation (portrait, landscape)

=item

Footer_size 	rows in footer

=item

File_name		output file name

=item

Source		Data source (Datasource class descendant)

=item

Breaks		Hash reference, which contains the breaks information

=item

SubHeader		function reference, which will be called to print the report header

=item

SubTitle		function reference, which will be called to print the report title

=item

SubDetail		function reference, which will be called to print every report detail

=item

SubFooter		function reference, which will be called to print the report footer

=item

SubFinal		function reference, which is called when all data has been processed

=item

SubPrint		function reference, which is called when the report is created

=back

=item

$report->generate()		Generates the report. Returns 0 if OK, 2 if there was no data

=head1 SPECIAL FUNCTIONS

=item

$report->page()		returns the page number

=item

$report->date(n)	returns the date in a specific format. n is the format code. Currently, there are only 2 formats 

 1		dd/mm/aaaa
 2		mm/dd/aaaa

=item

$report->time(n)	returns the time in a specific format. n is the format code. Currently, there is only 1 format 

 1    hh:mm 

=head1 SPECIAL VARIABLES


=item

$report->{EOR}		indicates the end of report

=item

$report->{BOR}		indicates the begining of the report

=item

$report->{NEWPAGE}	indicates that a new page is required

=item

$report->{NEWREPORT}=FILE indicates that the data processed up to this point should be stored in file FILE.

=head1 EVENT FUNCTIONS

Each event function (Header, Title, Detail, Break, Foooter, Final), is called automatically when neccesary, passing them the following parameters:

=over 4

=item

report		which can be used to access the special variables

=item

sheet		blank sheet where the output will be defined (see RepFormat pod documentation)

=item

actual_reg	actual processing register

=item

last_reg		last processing register

=back

=over 8

=head2 HEADER FUNCTION

This functions is called each time when a new page is required 

=head2 TITLE FUNCTION

This function is called after the header, and breaks functions.

=head2 DETAIL FUNCTION

This function is called for every data record

=head2 FOOTER FUNCTION

This functions is called at the end of each page

=head2 FINAL FUNCTION

This function is called after the last record has been processed for the detail function

=head2 BREAK FUNTIONS

These functions are called when the break field of the function has changed (see BREAKS section). These functions are called before the detail function for the actual register.

=back

=head1 BREAKS

=item GENERALS

Each break is defined with a break field and a break function. For example:

assume we have the following data:

 1 2
 1 3
 2 4

If we want a break for the first field, that prints the sum of the second field, we have to define the following hash

$breaks{0} = \&sub_break;

where sub_break is the function where the output is defined. We have to define the sum for each record in the 'detail' function

 sub detail ( .....
 ...
 $sum += $field[1];
 ....

so we can do

 sub sub_break ( ....
 ...
 $sheet->Print("the sum is $sum");
 $sum = 0; #reset $sum
 ...


As many breaks as necessary can be defined, but only one break per field is allowed.

=item CASCADE BREAKS

When defining more that one Break, they are handled in cascade. A change in a break field will cause all the break functions defined for fields with a lower value to be called. For example

assume the following data

 1 2 3 1 1
 1 2 3 1 2
 1 2 4 2 3
 1 3 4 2 4

and the following break hash

 $breaks{0} = \&break1;
 $breaks{1} = \&break2;
 $breaks{3} = \&break3;

in the third register, the field #3 changes. This will cause the functions break1, break2 and break3 to be called. The order in which these functions are called are from the left most to the right most one.

In the fourth register the field #2 changes, so functions break1 and break2 will be called, in this order.

=head1 DATASOURCES

This indicates the source for the report data. It can be a Database or a plain ascii file.

Internally, Data::Reporter uses this object to retreive data. This object should have a function 'getdata' defined, which receives a function reference that will be called on each record.

This approach allows to have diferent data sources. At this point the only sources available are a Sybase database and a plain ascii file, but sources for others databases can easily be implemented.

=cut

package Reporter;
$VERSION = 1.0;
use Data::Reporter::RepFormat;
use Data::Reporter::Datasource;
use Carp;
use English;
use File::Copy;
use strict;
use vars qw($myself);
$|=1;

sub new (%) {
	my $class = shift;
	my $self={};
	bless $self, $class;
	$self->_initialize();
	if (@_ > 0) {
		my %param = @_;
		$self->_getparam(%param);
	}
	$self;
}

sub configure(%) {
	my $self = shift;
	$self->_getparam(@_);
}

sub generate($) {
	my $self = shift;
	$myself = $self;

	$self->_init_report();

	$self->{SOURCE}->getdata(\&_process_detail);

	$self->{EOR} = 1;
	$self->_process_detail(@{$self->{LASTREG}}) if ($self->{THEREISINFO});

	$self->_end_report();

	if ($self->{THEREISINFO}) {
		return 0;
	} else {
		return 2;
	}
}

sub page($$) {
	my $self = shift;
	my $op = shift;
	my $retval = "";
	if ($op == 1) {
		$retval = sprintf("%3d",$self->{PAGE});
	}
	return $retval;
}

sub date($$) {
	my $self = shift;
	my $op = shift;
	my $retval = "";
	my @date = localtime();
	my $year = $date[5];
	if ($year > 100) {
		$year -= 100;
		$year = "20".$year;
	} else {
		$year = "19".$year;
	}
	
	if ($op == 1) {
		$retval = sprintf("%02s/%02s/%4s",$date[3],$date[4]+1,$year);
	} elsif ($op == 2) {
		$retval = sprintf("%02s/%02s/%4s",$date[4]+1,$date[3],$year);
	}
	return $retval;
}

sub time($$) {
	my $self = shift;
	my $op = shift;
	my $retval = "";
	my @date = localtime();

	if ($op == 1) {
		$retval = sprintf("%02s:%02s",$date[2],$date[1]);
	}
	return $retval;
}

sub _initialize($) {
	my $self = shift;
	#create special variables
	$self->{ACTLINE} = 1;	#line indicator inside the page
	$self->{NEWPAGE} = 1;	#indicator to make new page
	$self->{PAGE} = 0;		#page indicator
	$self->{EOR} = 0;			#end of report indicator
	$self->{LASTBREAK} = 0;	#indicator for last break to process
	$self->{BOR} = 1;			#indicator for begin of report
	$self->{NEWREP} = "";	#file to save the actual information and begin
							# a new report
	$self->{OS_WIN} = $^O eq 'MSWin32';

	#path to save work file
	if ($self->{OS_WIN}) {
		$self->{OUTPUTPATH} = "C:\\WINDOWS\\TEMP\\";
	} else {
		$self->{OUTPUTPATH} = "/tmp/";
	}

	#default report size
	$self->{WIDTH} = 80;
	$self->{HEIGHT} = 60;

	#default rows
	$self->{ROWS} = 60;

	#create Forms
	$self->_create_forms();

	#create actual and last regs
	$self->{ACTREG} = [];
	$self->{LASTREG} = [];

	$self->{ORIENTATION} = "portrait";

	#by default there is no info
	$self->{THEREISINFO} = 0;

	#by default is not the last break to process
	$self->{LASTBREAK}
}

sub _create_forms($) {
	my $self= shift;

	#form for title, header and footer
	$self->{FORMATFORM} = new RepFormat($self->{WIDTH}, $self->{HEIGHT});

	#form from details and breaks
	$self->{DATAFORM} = new RepFormat($self->{WIDTH}, $self->{HEIGHT});
}

sub _getparam(%){
	my $self=shift;
	my %param = @_;
	foreach my $key (keys %param) {
		if ($key eq "SubHeader") {
			$self->{SUBHEADER} = $param{$key};
		} elsif ($key eq "SubTitle") {
			$self->{SUBTITLE} = $param{$key};
		} elsif ($key eq "SubDetail") {
			$self->{SUBDETAIL} = $param{$key};
		} elsif ($key eq "SubFooter") {
			$self->{SUBFOOTER} = $param{$key};
		} elsif ($key eq "SubFinal") {
			$self->{SUBFINAL} = $param{$key};
		} elsif ($key eq "SubPrint") {
			$self->{SUBPRINT} = $param{$key};
		} elsif ($key eq "Source") {
			$self->{SOURCE} = $param{$key};
			croak "parameter Source is not a Datasource descendent\n"
							unless ($self->{SOURCE}->isa("Datasource"));
		} elsif ($key eq "Breaks") {
			$self->_gen_breaks_info($param{$key});
		} elsif ($key eq "File_name") {
			$self->{FILE_NAME} = $param{$key};
		} elsif ($key eq "Width") {
			$self->{WIDTH} = $param{$key};
			if ($self->{WIDTH} <= 0) {
				croak "Invalid value ($self->{WIDTH}) for Width";
			}
			$self->_create_forms();
		} elsif ($key eq "Height") {
			$self->{HEIGHT} = $param{$key};
			if ($self->{HEIGHT} <= 0) {
				croak "Invalid value ($self->{HEIGHT}) for Height";
			}
			$self->_create_forms();
		} elsif ($key eq "Footer_size") {
			$self->{FOOTER_SIZE} = $param{$key};
			if ($self->{FOOTER_SIZE} <= 0) {
				croak "Invalid value ($self->{FOOTER_SIZE}) for Footer_size";
			}
			$self->{ROWS} = $self->{HEIGHT} - $self->{FOOTER_SIZE};
		} elsif ($key eq "Orientation") {
			if ($param{$key} ne "portrait" or $param{$key} ne "landscape") {
				croak "Invalid orientation ($param{$key})";
			}
			$self->{ORIENTATION} = $param{$key};
		} else {
			croak "Parameter $key invalid (SubHeader, SubTitle, SubDetail, ".
				"SubFooter, Breaks, Name, Width, Height)";
		}
	}
}

sub _gen_breaks_info($%) {
	my $self = shift;
	my $breaks = shift;

	foreach my $field (keys %{$breaks}) {
		my @couple_val_routine = (0, $breaks->{$field});
		$self->{BREAKS}->{$field}=\@couple_val_routine;
	}
}

sub _blank($) {
	my $self=shift;
	print OUTPUTFILE "\n";
	$self->{ACTLINE}++;
}

sub _print_visform($$) {
	my $self = shift;
	my $totlines = shift;
	my $kind_of_info = shift;
	my $format;

	if ($kind_of_info == 1) {
		$format = $self->{DATAFORM};
	} else {
		$format = $self->{FORMATFORM};
	}

	my $aux = 0;
	my $act_line = \$self->{ACTLINE};
	my $rows = $self->{ROWS};
	my $line = "";
	while ($totlines > 0) {
		$line = $format->Getline($aux);
		print OUTPUTFILE "$line\n";
		$aux++;
		$totlines--;
		${$act_line}++;
	}
}


sub _print_header($) {
	my $self = shift;
	$self->{PAGE}++;
	$self->{NEWPAGE} = 0 if ($self->{NEWPAGE});
	$self->{LINEAACT} = 1;
	$self->{FORMATFORM}->Clear();
	&{$self->{SUBHEADER}}($self, $self->{FORMATFORM},
										$self->{ACTREG}, $self->{LASTREG});
	my $lines = $self->{FORMATFORM}->Nlines();
	$self->_print_visform($lines, 0);
	$self->{ACTLINE} = $lines+1;
	$self->{BEGINOFPAGE} = 1;
}

sub _print_footer($) {
	my $self = shift;

	$self->{FORMATFORM}->Clear();
	&{$self->{SUBFOOTER}}($self, $self->{FORMATFORM},
										$self->{ACTREG}, $self->{LASTREG});
	my $lines = $self->{FORMATFORM}->Nlines();

	#check footer size
	if ($lines > $self->{FOOTER_SIZE}) {
		croak "Invalid number of lines of footer ($lines).".
												"Must be $self->{FOOTER_SIZE}";
	}

	#fill page with blanks
	my $act_line = \$self->{ACTLINE};
	my $rows = $self->{HEIGHT}-$self->{FOOTER_SIZE};
	while ($$act_line <= $rows) {
		$self->_blank();
	}

	#print footer
	$self->_print_visform($self->{FOOTER_SIZE}, 0);
}

sub _print_title($$) {
	my $self = shift;
	my $processing_info = shift;
	$self->{FORMATFORM}->Clear();
	if (!$processing_info) {
		&{$self->{SUBTITLE}}($self, $self->{FORMATFORM},
											$self->{ACTREG}, $self->{LASTREG});
	} else {
		&{$self->{SUBTITLE}}($self, $self->{FORMATFORM},
											$self->{LASTREG}, $self->{LASTREG});
	}
	my $lines = $self->{FORMATFORM}->Nlines();
	$self->_print_visform($lines, 0)
						unless ($self->_checknewpage($lines, $processing_info));
}

sub _newpage($$) {
	my $self = shift;
	my $processing_info = shift; #there is information from the previous
                                 #page
	if ($self->{BOR} == 0) {
		$self->_print_footer() if (defined($self->{SUBFOOTER}));
		print OUTPUTFILE $FORMAT_FORMFEED;
		my $aux = 1;
		while ( $aux < $self->{NEWPAGE} ) {
			print OUTPUTFILE $FORMAT_FORMFEED;
			$aux++;
		}
	} else {
		my $forma="";
		if ($self->{ORIENTATION} eq "landscape") {
			$forma = 'E&l1O&l1S&l2E&a0L&l12D(s16H&l95F&k2G';
			$forma =~ s/95/$self->{HEIGHT}/;
		} elsif ($self->{ORIENTATION} eq "portrait"){
		$forma = '&l95F';
		$forma =~ s/95/$self->{HEIGHT}/;
		}
		print OUTPUTFILE $forma;
	}

	$self->_print_header();
	$self->_print_title($processing_info);
}

sub _print_file($) {
	my $self = shift;
	&{$self->{SUBPRINT}}($self, "$self->{OUTPUTPATH}$self->{FILE_NAME}");
}

sub _newrep($) {
	my $self = shift;
	close(OUTPUTFILE);
	$self->_print_file() if (defined($self->{SUBPRINT}));
	$self->{FILE_NAME} = $self->{NEWREP};
	$self->_init_report();
}

sub _checknewpage($$) {
	my $self = shift;
	my $rowstoprint = shift;
	my $processing_info = shift;
	my $retval = 0;

	if ($rowstoprint + $self->{ACTLINE} - 1 > $self->{ROWS}) {
		$self->_newpage($processing_info);
		$retval = 1;
	}
	return $retval;
}

sub _process_breaks() {
	my $self = shift;
	my $regact = $self->{ACTREG};
	my @couple_val_routine;
	my @indexes_array= ();
	my $index = 0;
	my $maxindex = -1;
	my $breaks = $self->{BREAKS};
	foreach my $field (sort(keys %{$breaks}) ) {
		@couple_val_routine = @{$breaks->{$field}};
		if (($self->{EOR} || $couple_val_routine[0] ne @{$regact}[$field])
													&& $self->{BOR} != 1) {
			$maxindex = $index;
		}
		$indexes_array[$index] = $field;
		$index++;
		@{$breaks->{$field}}[0] = @{$regact}[$field];
	}

	$index = 0;
	my $newpage=0;
	while ($index <= $maxindex) {
		@couple_val_routine = @{$breaks->{$indexes_array[$index]}};
		$index++;
		$self->{LASTBREAK} = 1 if ($index > $maxindex);
		$self->{DATAFORM}->Clear();
		$newpage = 0;
		&{$couple_val_routine[1]}($self, $self->{DATAFORM},
											$self->{LASTREG}, $self->{LASTREG});
		my $lines = $self->{DATAFORM}->Nlines();
		$newpage = $self->{NEWPAGE} if ($self->{NEWPAGE});
		if ($lines) {
			$self->_checknewpage($lines, 1);
			$self->_print_visform($lines, 1);
			if ($newpage) {
				if ($index > $maxindex) {
					$self->_newpage(0);
				} else {
				$self->{NEWPAGE} = $newpage;
				$self->_newpage(1);
				}
			}
		}
	}

	$self->{LASTBREAK} = 0;
	$self->_newrep() if ($self->{NEWREP} ne "");
	if (($index > 0) && ($self->{EOR} == 0) && ($self->{NEWREP} eq "")
											&& (!$self->{BEGINOFPAGE})) {
		$self->_blank();
		$self->_print_title(0);
	}
	$self->{NEWREP} = "";
}

sub _print_detail($) {
	my $self = shift;
	$self->{DATAFORM}->Clear();
	&{$self->{SUBDETAIL}}($self, $self->{DATAFORM},
											$self->{ACTREG}, $self->{LASTREG});
	my $lines = $self->{DATAFORM}->Nlines();
	$self->_checknewpage($lines, 0);
	$self->_print_visform($lines, 1);
	$self->{BEGINOFPAGE} = 0;
	$self->_newpage(0) if ($self->{NEWPAGE});
}

sub _print_final($) {
	my $self = shift;
	$self->{DATAFORM}->Clear();
	&{$self->{SUBFINAL}}($self, $self->{DATAFORM},
											$self->{ACTREG}, $self->{LASTREG});
	my $lines = $self->{DATAFORM}->Nlines();
	$self->_checknewpage($lines, 0);
	$self->_print_visform($lines, 1);
}

sub _process_detail(@) {
	my $self = $myself;
	my @act_data = @_;

	$self->{THEREISINFO} = 1;
	$self->{ACTREG} = \@act_data;

	$self->_newpage(0) if ($self->{BOR});

	$self->_process_breaks() if (defined($self->{BREAKS}));

	$self->_print_detail() unless ($self->{EOR});

	if ($self->{EOR}) {
		if (defined($self->{SUBFINAL})){
			$self->_print_final();
		}
		$self->_print_footer() if (defined($self->{SUBFOOTER}));
	}
	$self->{BOR} = 0;
	$self->{LASTREG} = $self->{ACTREG};
}

sub _init_report($) {
	my $self=shift;
	open (OUTPUTFILE, ">$self->{OUTPUTPATH}/report.out")
										|| croak "Can't create file report.out";
	$self->{PAGE} = 0;
	$self->{BOR}=1;
}

sub _end_report($) {
	my $self=shift;
	close OUTPUTFILE;
	$self->_print_file() if (defined($self->{SUBPRINT}));
	copy "$self->{OUTPUTPATH}/report.out", $self->{FILE_NAME};
}

1;
