#!/usr/local/bin/perl -wc

=head1 NAME

Sybsource - Reporter Handler for sybase connection

=head1 SYNOPSIS

	use Data::Reporter::Sybsource;

	$source = new Sybsource(File => $file,
				Arguments => $info,
				Query => $query);

		$file 		- information file about connection login
		$info		- array reference (usr, pwd, db, srv) about connection login
		$query		- query to execute for getting data

	$source->configure(option => value, ...);
	$subru = sub {print "record -> $_\n"};
	$source->getdata($subru);

=head1 DESCRIPTION

=item new()

Creates a new handler to manipulate the sybase information.

=item $source->configure(option => value)

=over 4

valid options are:

=item

File			Information file about connection login. The file must have the following information: user, password, database, server. These items must come in this order, each on a separate line.

=item

Arguments		array reference with the following information: usr, pwd, db, srv. This can be used instead of the File option

=item

query		string with the query to execute to retrive the data

=back 4

=item $source->getdata($subru)

For each record of the query result, calls the function $subru, sending the record as parameter

=cut

package Sybsource;
use Sybase::Sybperl;
use Sybase::DBlib;
use Carp;
use Data::Reporter::Datasource;
@ISA =  qw(Datasource);
use strict;

sub new (%) {
	my $class = shift;
	my $self={};
	bless $self, $class;
	my %param = @_;
	$self->configure(%param);
	$self->_connect();
	$self;
}

sub configure($%) {
	my $self=shift;
	my %param = @_;
	foreach my $key (keys %param) {
		if ($key eq "File") {
			$self->{CONNECTIONINFO} = $self->_getfileparams($param{$key});
		} elsif ($key eq "Arguments") {
			my @data = @{$param{$key}};
			croak "Invalid arguments for conexion  (usr, pwd, db, srv)!!!"
				if (@data < 4);
			$self->{CONNECTIONINFO} = \@data;
		} elsif ($key eq "Query") {
			$self->{QUERY} = $param{$key};
		}
	}
}

sub getdata($$) {
	my $self = shift;
	my $routine = shift;
	croak "Query has not been defined!!!" unless (defined($self->{QUERY}));
	croak "Connection has not been defined!!!"
									unless (defined($self->{CONNECTIONINFO}));
	$self->{DBH}->sql($self->{QUERY}, $routine);
}

sub _getfileparams($$) {
	my $self = shift;
	my $file = shift;

	open FILECON, $file or croak "Can't open file $file!!!";
	my @data = <FILECON>;
	close FILECON;
	
	croak "file error: $file!!!" if (@data < 4);
	my $usr = $data[0];
	my $pas = $data[1];
	my $db  = $data[2];
	my $srv = $data[3];
	chomp($usr);
	chomp($pas);
	chomp($db);
	chomp($srv);
	return [$usr, $pas, $db, $srv];
}

sub _connect($) {
	my $self = shift;
	my ($usr, $pass, $db, $srv) = @{$self->{CONNECTIONINFO}};
	$self->{DBH} = new Sybase::DBlib $usr, $pass, $srv;
	croak "Conexion failed with user = $usr, password = $pass, server $srv"
												unless (defined($self->{DBH}));
	$self->{DBH}->dbuse($db);
}


1;
