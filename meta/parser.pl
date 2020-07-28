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
#      ├── data_cleaner.py
#      ├── Newlog_gen.py
#      ├── SVS_New_Logs
#      └── SVS_Proc_Data


use warnings;
use strict;

use List::Util qw(min max);
use Statistics::Basic qw(median);

my %timeframes = ( # where each song begins and ends, in seconds
    1 => { start =>     5, end =>   142, },
    2 => { start =>   155, end =>   275, },
    3 => { start =>   454, end =>   502, },
    4 => { start =>   507, end =>   642, },
    5 => { start =>   790, end =>   973, },
    6 => { start =>   978, end =>  1088, },
    7 => { start =>  1213, end =>  1349, },
    8 => { start =>  1359, end =>  1504, },
);

my $sample_freq = 25;

my ($din, $dout) = ('./ImprovisationSynchronization/SVS_Proc_Data', './ConcertHall/_data');
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

            $fout = "$dout/$piece.json";
            open $FOUT, ">>", $fout or die "Can't open '$fout'";

            if (-z $fout) {
                print $FOUT "{\n";
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

    my $count = 0;
    my ($x, $y, $z) = (0, 0, 0);
    my @xs;
    my @ys;
    my @zs;

    while (<$FIN>) {
        chomp;

        $count ++;

        # [timestamp],[horizontal],[front],[vertical]
        if ( /([^,]+),$val_re,$val_re,$val_re/ ) {

            if ($count >= $sample_freq * $timeframes{$piece}->{start} &&
                $count <= $sample_freq * $timeframes{$piece}->{end}) {

                $x = $2 + 0.0;
                $y = $3 + 0.0;
                $z = $4 + 9.81;

                push @xs, $x;
                push @ys, $y;
                push @zs, $z;

                print $FOUT "[$x,$y,$z], ";
            }
            elsif ($count > $sample_freq * $timeframes{$piece}->{end}) {
                last;
            }
        }
    }
    print $FOUT "],\n";
    print $FOUT "  \"count\" : " . $count . ",";
    if ($count != 0) {
        print $FOUT "  \"median\" : [" . median(@xs) . "," . median(@ys) . "," . median(@zs) . "] ";
    }
    else {
        print $FOUT "  \"median\" : [ NaN, NaN, NaN ] \n";
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

