#!/usr/local/bin/perl
use strict;
use Data::Reporter::Reporter;
use Data::Reporter::RepFormat;
use Data::Reporter::Filesource;

use vars qw($filial $ajustot $precostot $comistot $nopzastot $prefartot $totnotas);

sub HEADER($$$$) { 
	my ($report, $sheet, $rep_actline, $rep_lastline) = @_;
	my @field=();
	$field[0] = $sheet->Center($filial, 105);
	$sheet->MVPrint(40, 0,"CASA AUTREY S.A. DE C.V.                               ");
	$sheet->MVPrint(95, 0,$report->date(1));
	$sheet->MVPrint(0, 1,$field[0]);
	$sheet->MVPrint(42, 2,"LOCAL INVOICE SYSTEM");
	$sheet->MVPrint(36, 3,"BENAVIDES'S INVOICES DESCRIPTION");
	$sheet->MVPrint(0, 4,"AVEF5803/v.1.0                                                                                  ");
	$sheet->MVPrint(96, 4,"PAG : ".$report->page(1));
	$sheet->MVPrint(0, 5,"-" x 105);
}

sub TITLE($$$$) { 
	my ($report, $sheet, $rep_actline, $rep_lastline) = @_;
	my @field=();

	$sheet->MVPrint(4, 0,"Invoice      Cust. ID      Adjust       Note      Prov. Cost    Commission    Pieces    Phar. cost");
	$sheet->MVPrint(0, 1,"--------------- --------- -------------- --------- -------------- -------------- --------- --------------");
}

sub DETAIL($$$$) { 
	my ($report, $sheet, $rep_actline, $rep_lastline) = @_;
	my @field=();
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
	$sheet->MVPrint(0, 0,$field[0]);
	$sheet->MVPrint(40, 0,$field[3]);
	$sheet->MVPrint(50, 0,$field[4]);
	$sheet->MVPrint(15, 0,$field[1]);
	$sheet->MVPrint(25, 0,$field[2]);
	$sheet->MVPrint(80, 0,$field[6]);
	$sheet->MVPrint(90, 0,$field[7]);
	$sheet->MVPrint(65, 0,$field[5]);
}

sub nomb_filial() {	
	return "SUCURSAL MONTERREY";
}

sub FINAL($$$$) { 
	my ($report, $sheet, $rep_actline, $rep_lastline) = @_;
	my @field=();
	$field[0] = $sheet->Commify(sprintf("%15.2f", $ajustot));	
	$field[1] = $sheet->Commify(sprintf("%15.2f", $precostot));	
	$field[2] = $sheet->Commify(sprintf("%15.2f", $comistot));	
	$field[3] = sprintf("%10d", $nopzastot);	
	$field[4] = $sheet->Commify(sprintf("%15.2f", $prefartot));	
	$field[5] = sprintf("%10d", $totnotas);
	$sheet->MVPrint(25, 0,"---------------           -------------- -------------- --------- --------------");
	$sheet->MVPrint(50, 1,$field[1]);
	$sheet->MVPrint(5, 1,"Total amount  :     ");
	$sheet->MVPrint(25, 1,$field[0]);
	$sheet->MVPrint(80, 1,$field[3]);
	$sheet->MVPrint(90, 1,$field[4]);
	$sheet->MVPrint(65, 1,$field[2]);
	$sheet->MVPrint(0, 3,"Total number of notes  : ");
	$sheet->MVPrint(25, 3,$field[5]);
	$sheet->MVPrint(0, 5,"End of report");
}

#MAIN
{
	$ajustot = 0.0;	
	$precostot = 0.0;	
	$comistot = 0.0;	
	$nopzastot = 0.0;	
	$prefartot = 0.0;	
	$totnotas = 0;	
	$filial = nomb_filial();
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
}
