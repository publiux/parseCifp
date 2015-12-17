#!/usr/bin/perl
# Copyright (C) 2014  Jesse McGraw (jlmcgraw@gmail.com)

# Process CIFP data provided by the FAA in ARINC424 version 18 format

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see [http://www.gnu.org/licenses/].

use 5.010;
use strict;
use warnings;
use File::Basename;
use Getopt::Std;
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
use vars qw/ %opt /;

#Allow use of locally installed libraries in conjunction with Carton
use FindBin '$Bin';
use lib "$FindBin::Bin/local/lib/perl5";

#Non-standard libaries
use DBI;
use Parse::FixedLength;

my $opt_string = 'vec:';

my $arg_num = scalar @ARGV;

unless ( getopts( "$opt_string", \%opt ) ) {
    usage();
    exit(1);
}
if ( $arg_num < 1 ) {
    usage();
    exit(1);
}

#Get the target data directory from command line options
my $targetdir = $ARGV[0];

#Other command line parameters
my $debug  = $opt{v};
my $shouldExpand = $opt{e};
my $cycle = $opt{c};

#Open appropriate data file in the target directory
my ( $filename, $dir, $ext ) = fileparse( $targetdir, qr/\.[^.]*/ );
my $datafile = "$dir" . "FAACIFP18" ;# . "-$cycle";

my $file;
open $file, '<', $datafile or die "cannot open $datafile: $!";



#Hash to hold whether we have already created table for this file and recordType
my %haveCreatedTable = ();

my %parameters = (
    'autonum' => 'true',

    # 'trim'    => 'true',
);

#Load the hash defintion of sections in an external file
my %sections = do 'sections.pl';

#Load the hash defintion from an external file
#These are parsers for each section/subsection combo we expect to find
#This is really the meat of the whole program
my %hash_of_parsers = do 'parsers.pl';

#Load the hash defintion from an external file
#Use these parsers for continuation records
my %hash_of_continuation_base_parsers = do 'continuation_base_parsers.pl';

#Load the hash defintion from an external file
#Use these continuation parsers for SectionCode/SubsectionCodes that have application types
my %hash_of_continuation_application_parsers  = do 'continuation_application_parsers.pl';


#A hash to record SectionCode/SubsectionCode/ApplicationType that we've encountered
my %continuationAndApplicationTypes = ();

#A parser for the common information for a record to determine which more specific parser to use
my $parser_base = Parse::FixedLength->new(
    [
        qw(
          RecordType:1
          CustomerAreaCode:3
          SectionCode:1
          SubSectionCode:1
          Remainder:126
          )
    ]
);

#For whatever silly reason, subsection codes are in a different place in airport and heliport records
#So we'll define another parser to get the subsection code for them
my $parser_airportheliport = Parse::FixedLength->new(
    [
        qw(
          RecordType:1
          CustomerAreaCode:3
          SectionCode:1
          BlankSpacing:1
          AirportICAOIdentifier:4
          ICAOCode:2
          SubSectionCode:1
          Remainder:119
          )
    ]
);

#create/connect to the database
my $dbfile = "./cifp-$cycle.db";
my $dbh = DBI->connect( "dbi:SQLite:dbname=$dbfile", "", "" );

#Set some parameters to speed INSERTs up at the expense of safety
# $dbh->do("PRAGMA page_size=4096");
$dbh->do("PRAGMA synchronous=OFF");

#Create base tables (obviously just for Android)
my $create_metadata_table  = "CREATE TABLE android_metadata ( locale TEXT );";
my $insert_metadata_record = "INSERT INTO android_metadata VALUES ( 'en_US' );";

$dbh->do("DROP TABLE IF EXISTS android_metadata");
$dbh->do($create_metadata_table);
$dbh->do($insert_metadata_record);

#Loop over each line of CIFP file
while (<$file>) {
    my $textOfCurrentLine = $_;
    my $currentLineNumber = $.;

    #Default information about this record
    my $primary_or_continuation = "primary";
    my $application             = "base";

    #Remove linefeed characters
    $textOfCurrentLine =~ s/\R//g;

    #Check for mismatch between expected and actual lengths
    die "Line # $currentLineNumber - Bad parse. Expected "
      . $parser_base->length
      . " characters but read "
      . length($textOfCurrentLine) . "\n"
      unless $parser_base->length == length($textOfCurrentLine);

    # say $currentLineNumber;
    # print "\rLoading # $currentLineNumber...";
    say "Loading # $currentLineNumber..." if ( $currentLineNumber % 1000 == 0 );

    #Start parsing the record
    my $data = $parser_base->parse_newref($textOfCurrentLine);

    my $RecordType       = $data->{RecordType};
    my $SectionCode      = $data->{SectionCode};
    my $SubSectionCode   = $data->{SubSectionCode};
    my $CustomerAreaCode = $data->{CustomerAreaCode};

    #Ignore header records
    if ( $RecordType eq 'H' ) {
        say "Line # $. : Header record:";
        next;
    }

    #Ignore non-standard records for now
    if ( $RecordType ne 'S' ) {
        say "Line # $. :"
          . "$sections{$SectionCode}{$SubSectionCode}:"
          . "$SectionCode$SubSectionCode";
        say "Non-standard record: $RecordType";
        next;
    }

    #Is this an airport or heliport record?
    if ( $SectionCode =~ m/[PH]/i ) {

        #If yes,  subsection codes are in a different place in airport and heliport records
        #Reparse and reset the variables
        $data = $parser_airportheliport->parse_newref($textOfCurrentLine);

        #Check for mismatch between expected and actual lengths
        die "Line # $currentLineNumber - Bad parse. Expected "
          . $parser_airportheliport->length
          . " characters but read "
          . length($textOfCurrentLine) . "\n"
          unless $parser_airportheliport->length == length($textOfCurrentLine);

        $RecordType       = $data->{RecordType};
        $SectionCode      = $data->{SectionCode};
        $SubSectionCode   = $data->{SubSectionCode};
        $CustomerAreaCode = $data->{CustomerAreaCode};
    }

    #Is there a parse format for this section/subsection?
    if ( not exists $hash_of_parsers{$SectionCode}{$SubSectionCode} ) {
        if ($debug) {
            say "$datafile line # $. :";
            say
              "Error:No parser defined for this SectionCode:$SectionCode and SubSectionCode:$SubSectionCode---";
        }
        next;
    }

    #Create an array to feed to Parse::FixedLength from the parser format we looked up in the hash_of_parsers
    my @parserArray =
      split( ' ', $hash_of_parsers{$SectionCode}{$SubSectionCode} );

    #Create the specific parser for this section/subsection
    my $parser_specific =
      Parse::FixedLength->new( [@parserArray], \%parameters );

    #Basic sanity check for the parser
    die "Bad length on parser_specific" if ( $parser_specific->length != 132 );

    #Check for mismatch between expected and actual lengths
    die "Line # $currentLineNumber - Bad parse. Expected "
      . $parser_specific->length
      . " characters but read "
      . length($textOfCurrentLine) . "\n"
      unless $parser_specific->length == length($textOfCurrentLine);

    # #Say what line of the source file we're working with and what section/subsection it is
    # say "Line # $. :"
    # . "$sections{$SectionCode}{$SubSectionCode}:"
    # . "$SectionCode$SubSectionCode";    #

    #Parse again with a more specific parser
    my $data2 = $parser_specific->parse_newref($textOfCurrentLine);

    #------------------------------------------------
    # #This is temporary code to process and print out AS - MORA records
    # if ( $SectionCode eq "A" && $SubSectionCode eq "S" ) {
    # # say $textOfCurrentLine;
    # my $startingLatitude  = $data2->{StartingLatitude};
    # my $startingLongitude = $data2->{StartingLongitude};

    # # say "startingLatitude: $startingLatitude, startingLongitude: $startingLongitude";
    # for ( my $i = 1 ; $i <= 30 ; $i++ ) {

    # my $mora = $data2->{ "MORA_" . $i };

    # # say "MORA: " . $data2->{"MORA_" . $i};
    # my $iZeroBased = sprintf( "%02d", $i - 1 );

    # my $currentLatitude  = $startingLatitude . "000000";
    # my $currentLongitude = $startingLongitude . "00" . "000";

    # # say "currentLatitude: $currentLatitude";
    # # say "currentLongitude: $currentLongitude";
    # my $currentLatitudeDecimal =coordinateToDecimalCifpFormat($currentLatitude);
    # my $currentLongitudeDecimal =coordinateToDecimalCifpFormat($currentLongitude);
    # $currentLongitudeDecimal = $currentLongitudeDecimal + $iZeroBased;
    # say "$currentLongitudeDecimal, $currentLatitudeDecimal, $mora";
    # }

    # # print Dumper($data2);
    # }
    #------------------------------------------------
    # #This is temporary code to print out runway records
    # if ( $SectionCode eq "P" && $SubSectionCode eq "G" ) {
    # #Have we already printed out the .csv header?
    # if ( $havePrintedKeys == 0 ) {
    # #Create these two keys for data we'll create in next step
    # $data2->{LatitudeDecimal}  = "";
    # $data2->{LongitudeDecimal} = "";
    # #Print the CSV header
    # foreach my $key ( sort keys $data2 ) {
    # print $key . ",";
    # }
    # say "";
    # $havePrintedKeys = 1;
    # }
    # E15028000000
    # #Calculate the decimal equivalents for given lat/lon values and add to hash
    # $data2->{LatitudeDecimal} =
    # coordinateToDecimalCifpFormat( $data2->{RunwayLatitude} );
    # $data2->{LongitudeDecimal} =
    # coordinateToDecimalCifpFormat( $data2->{RunwayLongitude} );

    # #Print the values of each hash key, sorted so they correspond with headers printed earlier
    # foreach my $key ( sort keys $data2 ) {
    # print $data2->{$key} . ",";
    # }
    # say "";
    # }

    #Work with continuation records

    #This is meant to check that records that should have {ContinuationRecordNumber} defined actually do.
    if ( not defined $data2->{ContinuationRecordNumber} ) {
        say "No continuation number for this record";
        say
          "$datafile line # $. : SectionCode:$SectionCode and SubSectionCode:$SubSectionCode---";

        # say "$textOfCurrentLine";
    }

    #Is the next record a continuation record?
    elsif ( $data2->{ContinuationRecordNumber} eq '1' ) {

        # if ($debug) {
        # say "Next record is a continuation record";
        # # print Dumper($data2);
        # say $textOfCurrentLine;
        # }
    }

    #Is this record a continuation record?  If ContinuationRecordNumber > 1 (goes into A..Z too) then it is)
    elsif (( $data2->{ContinuationRecordNumber} ne '0' )
        && ( $data2->{ContinuationRecordNumber} ne '1' ) )
    {
        # say "This record is a continuation record for $SectionCode-$SubSectionCode";
        # say "$textOfCurrentLine";
        $primary_or_continuation = "continuation";

        #Is there a base continuation parser for this?
        if ( $hash_of_continuation_base_parsers{$SectionCode}{$SubSectionCode} )
        {
            # say
            # "$datafile line # $. : SectionCode:$SectionCode and SubSectionCode:$SubSectionCode---";
            #Create an array to feed to Parse::FixedLength from the parser format we looked up in the hash_of_continuation_parsers
            @parserArray =
              split( ' ',
                $hash_of_continuation_base_parsers{$SectionCode}
                  {$SubSectionCode} );

            #Create the basic continuation parser for this section/subsection pair
            my $parser_continuation_base =
              Parse::FixedLength->new( [@parserArray], \%parameters );

            #Check for mismatch between expected and actual lengths
            die "Line # $currentLineNumber - Bad parse. Expected "
              . $parser_continuation_base->length
              . " characters but read "
              . length($textOfCurrentLine) . "\n"
              unless $parser_continuation_base->length ==
              length($textOfCurrentLine);

            #Parse the line with the base parser
            $data2 =
              $parser_continuation_base->parse_newref($textOfCurrentLine);

            # say "This record is a continuation record";
            # say
            # "$datafile line # $. : SectionCode:$SectionCode and SubSectionCode:$SubSectionCode---";

            #Pull out the application type
            $application = $data2->{ApplicationType};

            #Mark what we found
            $continuationAndApplicationTypes{$SectionCode}{$SubSectionCode}
              {$application} = 1;
              
#             say "{$SectionCode}{$SubSectionCode}{$application}";

            #Is there an application specific parser for this?
            if ( $hash_of_continuation_application_parsers{$SectionCode}
                {$SubSectionCode}{$application} )
            {
                #Re-parse with the application specific parser
                @parserArray =
                  split( ' ',
                    $hash_of_continuation_application_parsers{$SectionCode}
                      {$SubSectionCode}{$application} );

                my $parser_continuation_application =
                  Parse::FixedLength->new( [@parserArray], \%parameters );

                #Check for mismatch between expected and actual lengths
                die "Line # $currentLineNumber - Bad parse. Expected "
                  . $parser_continuation_application->length
                  . " characters but read "
                  . length($textOfCurrentLine) . "\n"
                  unless $parser_continuation_application->length ==
                  length($textOfCurrentLine);

                #Parse again with a more specific parser
                $data2 =
                  $parser_continuation_application->parse_newref(
                    $textOfCurrentLine);
            }
            else {
                #We don't have application continuation parser
                say
                  "$datafile line # $. : SectionCode:$SectionCode, SubSectionCode:$SubSectionCode, ApplicationType: $application---No continuation parser for this record";

                say "$textOfCurrentLine";

            }

        }
        else {
            #We don't have continuation parser
            say
              "$datafile line # $. : SectionCode:$SectionCode and SubSectionCode:$SubSectionCode---No continuation parser for this record";

            say "$textOfCurrentLine";

            #Mark what we found
            $continuationAndApplicationTypes{$SectionCode}{$SubSectionCode}
              {$application} = 1;

            # die;
        }
    }

    # #Add the raw text of this line in just for reference
    # $data2->{rawTextOfCurrentLine} = $textOfCurrentLine;

    #Create the table for each recordType if we haven't already
    #uses all the sorted keys in the hash as column names
    unless ( $haveCreatedTable{$primary_or_continuation}{$SectionCode}
        {$SubSectionCode}{$application} )
    {

        #Drop any existing table
        my $drop =
            'DROP TABLE IF EXISTS "'
          . $primary_or_continuation . "_"
          . $SectionCode . "_"
          . $SubSectionCode . "_"
          . $application . "_"
          . $sections{$SectionCode}{$SubSectionCode} . '"';

        $dbh->do($drop);

        #Makes a "CREATE TABLE" statement based on the keys of the hash, columns sorted alphabetically
        my $createStmt =
            'CREATE TABLE "'
          . $primary_or_continuation . "_"
          . $SectionCode . "_"
          . $SubSectionCode . "_"
          . $application . "_"
          . $sections{$SectionCode}{$SubSectionCode}
          . '" (_id INTEGER PRIMARY KEY AUTOINCREMENT,'
          . join( ',', sort { lc $a cmp lc $b } keys $data2 ) . ')';

        # Create the table
        # say $createStmt . "\n";
        # say "";
        $dbh->do($createStmt);

        #Mark it as created so we don't try to create again
        $haveCreatedTable{$primary_or_continuation}{$SectionCode}
          {$SubSectionCode}{$application} = 1;
    }

    #-------------------
    #Make an "INSERT INTO" statement based on the keys and values of the hash
    my $insertStmt =
        'INSERT INTO "'
      . $primary_or_continuation . "_"
      . $SectionCode . "_"
      . $SubSectionCode . "_"
      . $application . "_"
      . $sections{$SectionCode}{$SubSectionCode} . '" ('
      . join( ',', keys $data2 )
      . ') VALUES ('
      . join( ',', ('?') x keys $data2 ) . ')';

    #Insert the values into the database
    my $sth = $dbh->prepare($insertStmt);

    # my $sth = $dbh->prepare_cached($insertStmt);
    $sth->execute( values $data2 );

}

#Show what Sections and Subsections we found in this file
print Dumper( \%continuationAndApplicationTypes );
close($file);
exit;

sub coordinateToDecimalCifpFormat {

    #Convert a latitude or longitude in CIFP format to its decimal equivalent
    my ($coordinate) = shift;
    my ( $deg, $min, $sec, $signedDegrees, $declination, $secPostDecimal );
    my $data;

    #First parse the common information for a record to determine which more specific parser to use
    my $parser_latitude = Parse::FixedLength->new(
        [
            qw(
              Declination:1
              Degrees:2
              Minutes:2
              Seconds:2
              SecondsPostDecimal:2
              )
        ]
    );
    my $parser_longitude = Parse::FixedLength->new(
        [
            qw(
              Declination:1
              Degrees:3
              Minutes:2
              Seconds:2
              SecondsPostDecimal:2
              )
        ]
    );

    #Get the first character of the coordinate and parse accordingly
    $declination = substr( $coordinate, 0, 1 );

    given ($declination) {
        when (/[NS]/) {
            $data = $parser_latitude->parse_newref($coordinate);
            die "Bad input length on parser_latitude"
              if ( $parser_latitude->length != 9 );

            #Latitude is invalid if less than -90  or greater than 90
            # $signedDegrees = "" if ( abs($signedDegrees) > 90 );
        }
        when (/[EW]/) {
            $data = $parser_longitude->parse_newref($coordinate);
            die "Bad input length on parser_longitude"
              if ( $parser_longitude->length != 10 );

            #Longitude is invalid if less than -180 or greater than 180
            # $signedDegrees = "" if ( abs($signedDegrees) > 180 );
        }
        default {
            return -1;

        }
    }

    $declination    = $data->{Declination};
    $deg            = $data->{Degrees};
    $min            = $data->{Minutes};
    $sec            = $data->{Seconds};
    $secPostDecimal = $data->{SecondsPostDecimal};

    # print Dumper($data);

    $deg = $deg / 1;
    $min = $min / 60;

    #Concat the two portions of the seconds field with a decimal between
    $sec = ( $sec . "." . $secPostDecimal );

    # say "Sec: $sec";
    $sec           = ($sec) / 3600;
    $signedDegrees = ( $deg + $min + $sec );

    #Make coordinate negative if necessary
    if ( ( $declination eq "S" ) || ( $declination eq "W" ) ) {
        $signedDegrees = -($signedDegrees);
    }

    # say "Coordinate: $coordinate to $signedDegrees";           #if $debug;
    # say "Decl:$declination Deg: $deg, Min:$min, Sec:$sec";    #if $debug;

    return ($signedDegrees);
}
sub usage{
    say "Usage: $0 -v -e -c<cycle> <directory containing FAACIFP18>\n";
    say "-v: enable debug output";
    say "-e: expand text";
    return;
    }