#!/usr/local/bin/perl
#SIZE 80 66
#ORIENTATION portrait
#SOURCE Sybsource sybase.cfg
#QUERY select d.flfactura, clcliente, clfuerzavta, clruta, clproducto, mnprecxpzas, mnoftadesc, mndescuento from kdfactura d, kgfactura g where d.flfactura = g.flfactura and clstatusfact = "GU" and clcliente = 5982243 order by clfuerzavta, flfactura
#SECTION: DEFAULT_USES 0
#CODE AREA
use strict;
use Data::Reporter::Reporter;
use Data::Reporter::RepFormat;
use Data::Reporter::Sybsource;
#END

#SECTION: USES 0
#CODE AREA
use Sybase::Sybperl;
use Sybase::DBlib;
use vars qw($filial $totprecxpzas $totoftadesc $totdescuento 
		$totagtprec $totagtofta $totagtdesc);
#END

#SECTION: HEADER 0
sub HEADER($$$$) { 
	my ($report, $sheet, $rep_actline, $rep_lastline) = @_;
	my @field=();
#CODE AREA
	$field[0] = $sheet->Center($filial, 80);
#OUTPUT AREA
#ORIG LINE                              CASA AUTREY S.A. DE C.V                  @D1
	$sheet->MVPrint(29, 0,"CASA AUTREY S.A. DE C.V                  ");
	$sheet->MVPrint(70, 0,$report->date(1));
#ORIG LINE @F0
	$sheet->MVPrint(0, 1,$field[0]);
#ORIG LINE                               LOCAL INVOICE SYSTEM
	$sheet->MVPrint(30, 2,"LOCAL INVOICE SYSTEM");
#ORIG LINE                               INVOICES DESCRIPTION
	$sheet->MVPrint(30, 3,"INVOICES DESCRIPTION");
#ORIG LINE AVEF5804/v.1.1 @T1                                                    @P1
	$sheet->MVPrint(0, 4,"AVEF5804/v.1.1 ");
	$sheet->MVPrint(15, 4,$report->time(1));
	$sheet->MVPrint(70, 4,"PAG : ".$report->page(1));
#ORIG LINE --------------------------------------------------------------------------------
	$sheet->MVPrint(0, 5,"--------------------------------------------------------------------------------");
}
#END

#SECTION: TITLE 0
sub TITLE($$$$) { 
	my ($report, $sheet, $rep_actline, $rep_lastline) = @_;
	my @field=();
#CODE AREA
	$field[0] = $rep_actline->[0];	
	$field[1] = $rep_actline->[2];	
	$field[2] = $rep_actline->[1];	
	$field[3] = $rep_actline->[3];
#OUTPUT AREA
#ORIG LINE --------------------------------------------------------------------------------
	$sheet->MVPrint(0, 0,"--------------------------------------------------------------------------------");
#ORIG LINE Invoice   : @F0                                                    Agent : @F1
	$sheet->MVPrint(0, 1,"Invoice   : ");
	$sheet->MVPrint(12, 1,$field[0]);
	$sheet->MVPrint(75, 1,$field[1]);
	$sheet->MVPrint(67, 1,"Agent : ");
#ORIG LINE Customer  : @F2                                                     Rute : @F3
	$sheet->MVPrint(0, 2,"Customer  : ");
	$sheet->MVPrint(12, 2,$field[2]);
	$sheet->MVPrint(75, 2,$field[3]);
	$sheet->MVPrint(68, 2,"Rute : ");
#ORIG LINE --------------------------------------------------------------------------------
	$sheet->MVPrint(0, 3,"--------------------------------------------------------------------------------");
#ORIG LINE  Product                                 amount         oferr        discount
	$sheet->MVPrint(1, 4,"Product                                 amount         oferr        discount");
#ORIG LINE ----------                         --------------- -------------- --------------
	$sheet->MVPrint(0, 5,"----------                         --------------- -------------- --------------");
}
#END

#SECTION: DETAIL 0
sub DETAIL($$$$) { 
	my ($report, $sheet, $rep_actline, $rep_lastline) = @_;
	my @field=();
#CODE AREA
	$field[0] = sprintf("%10d",$rep_actline->[4]);	
	$field[1] = $sheet->Commify(sprintf("%15.2f",$rep_actline->[5]));	
	$field[2] = $sheet->Commify(sprintf("%15.2f",$rep_actline->[6]));	
	$field[3] = $sheet->Commify(sprintf("%15.2f",$rep_actline->[7]));	
	$totprecxpzas += $rep_actline->[5];	
	$totoftadesc  += $rep_actline->[6];	
	$totdescuento += $rep_actline->[7];
#OUTPUT AREA
#ORIG LINE @F0                                @F1            @F2            @F3
	$sheet->MVPrint(35, 0,$field[1]);
	$sheet->MVPrint(0, 0,$field[0]);
	$sheet->MVPrint(65, 0,$field[3]);
	$sheet->MVPrint(50, 0,$field[2]);
}
#END

#SECTION: FUNCTIONS 0
#CODE AREA
sub load_filial_name() {	
	open FILEPASS, "sybase.cfg" or die "Can´t open sybase.cfg $!";	
	my $usr = <FILEPASS>;	
	my $pas = <FILEPASS>;	
	my $bd  = <FILEPASS>;	
	my $srv = <FILEPASS>;   
	close FILEPASS;   
	chomp($usr);   
	chomp($pas);   
	chomp($bd);   
	chomp($srv);	
	my $dbh = new Sybase::DBlib($usr, $pas, $srv);	
	die "Can't connect to $srv" unless (defined($dbh));	
	$dbh->dbuse($bd);	
	my $subru = sub {		
		$filial = shift;	
	};	
	$dbh->sql("   		
		select razsocial from cfilial c, cconfigl g
		where c.clfilial=g.clfilial",         
	$subru);	
	$dbh->dbclose();
}
#END

#SECTION: FINAL 0
sub FINAL($$$$) { 
	my ($report, $sheet, $rep_actline, $rep_lastline) = @_;
	my @field=();
#CODE AREA

#OUTPUT AREA
#ORIG LINE End of report
	$sheet->MVPrint(0, 0,"End of report");
}
#END

#SECTION: BREAK_1 0
sub BREAK_1($$$$) { 
	my ($report, $sheet, $rep_actline, $rep_lastline) = @_;
	my @field=();
#CODE AREA
	$field[0] = sprintf("%10d",   $rep_actline->[0]);	
	$field[1] = $sheet->Commify(sprintf("%15.2f", $totprecxpzas));
	$field[2] = $sheet->Commify(sprintf("%15.2f", $totoftadesc));
	$field[3] = $sheet->Commify(sprintf("%15.2f", $totdescuento));
	$totagtprec += $totprecxpzas;	
	$totagtofta += $totoftadesc;	
	$totagtdesc += $totdescuento;	
	$totprecxpzas = 0.0;	
	$totoftadesc  = 0.0;	
	$totdescuento = 0.0;
#OUTPUT AREA
#ORIG LINE                                    --------------- -------------- --------------
	$sheet->MVPrint(35, 0,"--------------- -------------- --------------");
#ORIG LINE Totals of Invoice @F0              @F1            @F2            @F3
	$sheet->MVPrint(35, 1,$field[1]);
	$sheet->MVPrint(0, 1,"Totals of Invoice ");
	$sheet->MVPrint(18, 1,$field[0]);
	$sheet->MVPrint(65, 1,$field[3]);
	$sheet->MVPrint(50, 1,$field[2]);
#ORIG LINE 
#ORIG LINE 
#ORIG LINE 
}
#END

#SECTION: BREAK_2 2
sub BREAK_2($$$$) { 
	my ($report, $sheet, $rep_actline, $rep_lastline) = @_;
	my @field=();
#CODE AREA
	$field[0] = sprintf("%4d",$rep_actline->[2]);	
	$field[1] = $sheet->Commify(sprintf("%15.2f", $totagtprec));
	$field[2] = $sheet->Commify(sprintf("%15.2f", $totagtofta));
	$field[3] = $sheet->Commify(sprintf("%15.2f", $totagtdesc));
	$report->{NEWPAGE} = 1 if ($report->{EOR} == 0);
#OUTPUT AREA
#ORIG LINE                                    --------------- -------------- --------------
	$sheet->MVPrint(35, 0,"--------------- -------------- --------------");
#ORIG LINE Totals of agent @F0                @F1            @F2            @F3
	$sheet->MVPrint(35, 1,$field[1]);
	$sheet->MVPrint(0, 1,"Totals of agent ");
	$sheet->MVPrint(65, 1,$field[3]);
	$sheet->MVPrint(50, 1,$field[2]);
	$sheet->MVPrint(16, 1,$field[0]);
#ORIG LINE 
#ORIG LINE 
#ORIG LINE 
}
#END

#SECTION: MAIN 0
#CODE AREA
	load_filial_name();	
	$totprecxpzas 	= 0.0;	
	$totoftadesc 	= 0.0;	
	$totdescuento 	= 0.0;	
	$totagtprec 	= 0.0;	
	$totagtofta	= 0.0;	
	$totagtdesc	= 0.0;
#END

#SECTION: DEFAULT_MAIN 0
#CODE AREA
	my %rep_breaks = ();
	$rep_breaks{0} = \&BREAK_1;
	$rep_breaks{2} = \&BREAK_2;
	my $source = new Sybsource(File => "sybase.cfg",
		Query => 'select d.flfactura, clcliente, clfuerzavta, clruta, clproducto, mnprecxpzas, mnoftadesc, mndescuento from kdfactura d, kgfactura g where d.flfactura = g.flfactura and clstatusfact = "GU" and clcliente = 5982243 order by clfuerzavta, flfactura');
	my $report = new Reporter();
	$report->configure(
		Width	=> 80,
		Height	=> 66,
		SubFinal 	=> \&FINAL,
		Breaks	=> \%rep_breaks,
		SubHeader	=> \&HEADER,
		SubTitle	=> \&TITLE,
		SubDetail	=> \&DETAIL,
		Source	=> $source,
		File_name	=> "INVOICES"
	);
	$report->generate();
#END
