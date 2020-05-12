#!/usr/bin/perl

use warnings;
use strict;

use List::Util qw(min max);

my %timeframes = (
    1 => { start =>    10, end =>   147, },
    2 => { start =>   160, end =>   280, },
    3 => { start =>   459, end =>   507, },
    4 => { start =>   512, end =>   647, },
    5 => { start =>   795, end =>   978, },
    6 => { start =>   983, end =>  1093, },
    7 => { start =>  1218, end =>  1354, },
    8 => { start =>  1364, end =>  1509, },
);

my ($din, $dout) = ('./data', './out');
my ($fin, $fout, $FIN, $FOUT);

my ($piece) = @ARGV; 
my $seat;

printf "Processing piece %s\n", $piece;
foreach $fin (glob("$din/*.csv")) {
  
    if ($fin =~ /_(\w{3})[.]csv$/) {
        $seat = $1;
  
        printf "Processing file %s for seat %s", $fin, $seat;
  
        open $FIN, "<", $fin or die "Can't open '$fin'";
  
        $fout = "$dout/$piece.js";
        open $FOUT, ">>", $fout or die "Can't open '$fout'";

        if (-z $fout) {
        	if ($piece == 1) {
        		print $FOUT "window.data = {};\n";
        	}
            print $FOUT "window.data[$piece] = {\n";
        }
    
        process_csv($seat, $piece, $FIN, $FOUT);
        
        printf "\n";
        close $FIN or die "Can't close '$fin'";
    }
}

print $FOUT "\n};";
close $FOUT or die "Can't close '$fout'";


sub process_csv() {
    my ($seat, $piece, $FIN, $FOUT) = @_;

    print $FOUT "\"$seat\" : {\n";
    print $FOUT "  \"data\" : [ ";

    my ($sum, $vmin, $vmax, $count) = (0, 10000, 0, 0, 0);
    my $timestamp;

    while (<$FIN>) {
        chomp;

        if ( /(-?\d+(?:[.]\d+)?),(\d+),(.*)/ ) {

            $timestamp = $1 + 0;
            if ($timestamp >= $timeframes{$piece}->{start} && 
                $timestamp <= $timeframes{$piece}->{end}) {

                my $value = $3 + 0;
                $sum += $value;
                $vmin = min ($vmin, $value);
                $vmax = max ($vmax, $value);
	            $count += 1;

                print $FOUT "$value, ";
            }
            #elsif ($timestamp > $timeframes{$piece}->{end}) {
            #    last;
            #}    
        }
    }
    print $FOUT "],\n";
    print $FOUT "  \"count\" : " . $count . ",";
    print $FOUT "  \"avg\" : " . $sum / $count . ",";
    print $FOUT "  \"min\" : " . $vmin . ",";
    print $FOUT "  \"max\" : " . $vmax . "\n";
    print $FOUT "},\n";
}
