#!/usr/local/bin/perl
#SIZE 105 66
#ORIENTATION landscape
#SOURCE Filesource ajusbena.rep
#SECTION: DEFAULT_USES 0
#CODE AREA
use strict;
use Data::Reporter::Reporter;
use Data::Reporter::RepFormat;
use Data::Reporter::Filesource;
#END

#SECTION: USES 0
#CODE AREA
use vars qw($filial $ajustot $precostot $comistot $nopzastot $prefartot $totnotas);
#END

#SECTION: HEADER 0
sub HEADER($$$$) { 
	my ($report, $sheet, $rep_actline, $rep_lastline) = @_;
	my @field=();
#CODE AREA
	$field[0] = $sheet->Center($filial, 105);
#OUTPUT AREA
#ORIG LINE                                         CASA AUTREY S.A. DE C.V.                               @D1
	$sheet->MVPrint(40, 0,"CASA AUTREY S.A. DE C.V.                               ");
	$sheet->MVPrint(95, 0,$report->date(1));
#ORIG LINE @F0
	$sheet->MVPrint(0, 1,$field[0]);
#ORIG LINE                                           LOCAL INVOICE SYSTEM
	$sheet->MVPrint(42, 2,"LOCAL INVOICE SYSTEM");
#ORIG LINE                                     BENAVIDES'S INVOICES DESCRIPTION
	$sheet->MVPrint(36, 3,"BENAVIDES'S INVOICES DESCRIPTION");
#ORIG LINE AVEF5803/v.1.0                                                                                  @P1
	$sheet->MVPrint(0, 4,"AVEF5803/v.1.0                                                                                  ");
	$sheet->MVPrint(96, 4,"PAG : ".$report->page(1));
#ORIG LINE ---------------------------------------------------------------------------------------------------------
	$sheet->MVPrint(0, 5,"---------------------------------------------------------------------------------------------------------");
}
#END

#SECTION: TITLE 0
sub TITLE($$$$) { 
	my ($report, $sheet, $rep_actline, $rep_lastline) = @_;
	my @field=();
#CODE AREA

#OUTPUT AREA
#ORIG LINE     Invoice      Cust. ID      Adjust       Note      Prov. Cost    Commission    Pieces    Phar. cost
	$sheet->MVPrint(4, 0,"Invoice      Cust. ID      Adjust       Note      Prov. Cost    Commission    Pieces    Phar. cost");
#ORIG LINE --------------- --------- -------------- --------- -------------- -------------- --------- --------------
	$sheet->MVPrint(0, 1,"--------------- --------- -------------- --------- -------------- -------------- --------- --------------");
}
#END

#SECTION: DETAIL 0
sub DETAIL($$$$) { 
	my ($report, $sheet, $rep_actline, $rep_lastline) = @_;
	my @field=();
#CODE AREA
	$field[0] = sprintf("%15s",   $rep_actline->[0]);	
	$field[1] = sprintf("%10s",   $rep_actline->[1]);	
	$field[2] = $sheet->Commify(sprintf("%15.2f", $rep_actline->[2]));	
	$field[3] = sprintf("%10s",   $rep_actline->[3]);	
	$field[4] = $sheet->Commify(sprintf("%15.2f", $rep_actline->[4]));	
	$field[5] = $sheet->Commify(sprintf("%15.2f", $rep_actline->[5]));	
	$field[6] = sprintf("%10s",   $rep_actline->[6]);	
	$field[7] = $sheet->Commify(sprintf("%15.2f", $rep_actline->[7]));	
	$ajustot   += $rep_actline->[2];	
	$precostot += $rep_actline->[4];	
	$comistot  += $rep_actline->[5];	
	$nopzastot += $rep_actline->[6];	
	$prefartot += $rep_actline->[7];	
	$totnotas ++ if ($rep_actline->[2]  > 0);
#OUTPUT AREA
#ORIG LINE @F0            @F1       @F2            @F3       @F4            @F5            @F6       @F7
	$sheet->MVPrint(0, 0,$field[0]);
	$sheet->MVPrint(40, 0,$field[3]);
	$sheet->MVPrint(50, 0,$field[4]);
	$sheet->MVPrint(15, 0,$field[1]);
	$sheet->MVPrint(25, 0,$field[2]);
	$sheet->MVPrint(80, 0,$field[6]);
	$sheet->MVPrint(90, 0,$field[7]);
	$sheet->MVPrint(65, 0,$field[5]);
}
#END

#SECTION: FUNCTIONS 0
#CODE AREA
sub nomb_filial() {	
	return "SUCURSAL MONTERREY";
}
#END

#SECTION: FINAL 0
sub FINAL($$$$) { 
	my ($report, $sheet, $rep_actline, $rep_lastline) = @_;
	my @field=();
#CODE AREA
	$field[0] = $sheet->Commify(sprintf("%15.2f", $ajustot));	
	$field[1] = $sheet->Commify(sprintf("%15.2f", $precostot));	
	$field[2] = $sheet->Commify(sprintf("%15.2f", $comistot));	
	$field[3] = sprintf("%10d", $nopzastot);	
	$field[4] = $sheet->Commify(sprintf("%15.2f", $prefartot));	
	$field[5] = sprintf("%10d", $totnotas);
#OUTPUT AREA
#ORIG LINE                          ---------------           -------------- -------------- --------- --------------
	$sheet->MVPrint(25, 0,"---------------           -------------- -------------- --------- --------------");
#ORIG LINE      Total amount  :     @F0                      @F1            @F2            @F3       @F4
	$sheet->MVPrint(50, 1,$field[1]);
	$sheet->MVPrint(5, 1,"Total amount  :     ");
	$sheet->MVPrint(25, 1,$field[0]);
	$sheet->MVPrint(80, 1,$field[3]);
	$sheet->MVPrint(90, 1,$field[4]);
	$sheet->MVPrint(65, 1,$field[2]);
#ORIG LINE 
#ORIG LINE Total number of notes  : @F5
	$sheet->MVPrint(0, 3,"Total number of notes  : ");
	$sheet->MVPrint(25, 3,$field[5]);
#ORIG LINE 
#ORIG LINE End of report
	$sheet->MVPrint(0, 5,"End of report");
}
#END

#SECTION: MAIN 0
#CODE AREA
	$ajustot = 0.0;	
	$precostot = 0.0;	
	$comistot = 0.0;	
	$nopzastot = 0.0;	
	$prefartot = 0.0;	
	$totnotas = 0;	
	$filial = nomb_filial();
#END

#SECTION: DEFAULT_MAIN 0
#CODE AREA
	my $source = new Filesource(File => "ajusbena.rep");
	my $report = new Reporter();
	$report->configure(
		Width	=> 105,
		Height	=> 66,
		SubFinal 	=> \&FINAL,
		SubHeader	=> \&HEADER,
		SubTitle	=> \&TITLE,
		SubDetail	=> \&DETAIL,
		Source	=> $source,
		File_name	=> "BENAVIDES"
	);
	$report->generate();
#END
