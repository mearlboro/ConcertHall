#!/usr/bin/perl

# uses the new logs that have been preprocessed in
# github.com/mearlboro/ImprovisationSynchronization
# and produces data for the web visualisation

#  perl ConcertHall/meta/parser.pl 1
# run in the parent folder of the two repos to output the
# data where required, make sure it doesn't already exist
# in ConcertHall/data

#  .
#  ├── ConcertHall
#  │   ├── data
#  │   ├── index.html
#  │   ├── meta
#  │   ├── Newlog_gen.py
#  │   │   ├── parser.pl
#  │   │   └── sensors_to_seats.csv
#  │   ├── music
#  │   ├── script.js
#  │   └── styles.css
#  └── ImprovisationSynchronization
#      ├── Newlog_gen.py
#      └── SVS_New_Logs


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

my $sample_freq = 10;

my ($din, $dout) = ('./ImprovisationSynchronization/SVS_New_Logs', './ConcertHall/data');
my ($fin, $fout, $FIN, $FOUT);

my ($piece) = @ARGV;
my ($sensor, $seat);

my %sensors_to_seats = seats_sensors_csv();

my $val_re = qr/([-.\d]+)/;

printf "Processing piece %s\n", $piece;
foreach $fin (glob("$din/*.csv")) {

    if ($fin =~ /(SV\w{3})[.]csv$/) {
        $sensor = $1;
        $seat = $sensors_to_seats{$sensor};

        if ($seat) {
            printf "Processing file %s for device %s / seat %s", $fin, $sensor, $seat;

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
}

print $FOUT "\n};";
close $FOUT or die "Can't close '$fout'";


sub process_csv() {
    my ($sensor, $piece, $FIN, $FOUT) = @_;

    print $FOUT "\"$sensor\" : {\n";
    print $FOUT "  \"acc\" : [ ";

    my ($timestamp, $count) = (0, 0);
	my ($x, $y, $z, $xsum, $ysum, $zsum) = (0, 0, 0, 0, 0, 0);

    while (<$FIN>) {
        chomp;

        if ( /([^,]+),$val_re,$val_re,$val_re/ ) {

            if ($timestamp >= $sample_freq * $timeframes{$piece}->{start} &&
                $timestamp <= $sample_freq * $timeframes{$piece}->{end}) {

                $x = $2 + 0.0;
                $y = $3 + 9.81;
                $z = $4 + 0.0;

				$xsum += $x;
				$ysum += $y;
				$zsum += $z;

                $count ++;

                print $FOUT "[$x,$y,$z], ";
            }
            elsif ($timestamp > $sample_freq * $timeframes{$piece}->{end}) {
                last;
            }

            $timestamp ++;
        }
    }
    print $FOUT "],\n";
    print $FOUT "  \"count\" : " . $count . ",";
    if ($count != 0) {
        print $FOUT "  \"avg\" : [" . $xsum / $count . "," . $ysum / $count . "," . $zsum / $count . "] ";
    }
    else {
        print $FOUT "  \"avg\" : [ NaN, NaN, NaN ] \n";
    }

    print $FOUT "},\n";
}


sub seats_sensors_csv() {
    open my $FH, '<', "./ConcertHall/meta/sensors_to_seats.csv" or die "Can't open  'sensors_to_seats.csv'";

    my %hash;

    while (<$FH>) {
        chomp;

        if ( / (SV\d{3}) ; ([A-F]\d{2}) /ix ) {
            $hash{$1} = $2;
        }
    }

    return %hash;
}

