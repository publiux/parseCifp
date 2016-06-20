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
my $debug        = $opt{v};
my $shouldExpand = $opt{e};
my $cycle        = $opt{c};

#Open appropriate data file in the target directory
my ( $filename, $dir, $ext ) = fileparse( $targetdir, qr/\.[^.]*/ );
my $datafile = "$dir" . "FAACIFP18";    # . "-$cycle";

my $file;
open $file, '<', $datafile or die "cannot open $datafile: $!";

#Hash to hold whether we have already created table for this file and recordType
my %haveCreatedTable = ();

my %parameters = (
    'autonum' => 'true',
    'trim'    => 'true',
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
my %hash_of_continuation_application_parsers =
  do 'continuation_application_parsers.pl';

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

###Open an SQL transaction...
$dbh->begin_work();

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
    if ( $parser_base->length != length($textOfCurrentLine) ) {
        die "Line # $currentLineNumber - Bad parse. Expected "
          . $parser_base->length
          . " characters but read "
          . length($textOfCurrentLine) . "\n";
    }

    # print "\rLoading # $currentLineNumber...";
    say "Loading # $currentLineNumber..." if ( $currentLineNumber % 1000 == 0 );

    #Start parsing the record
    my $parser_ref = $parser_base->parse_newref($textOfCurrentLine);

    my $RecordType       = $parser_ref->{RecordType};
    my $SectionCode      = $parser_ref->{SectionCode};
    my $SubSectionCode   = $parser_ref->{SubSectionCode};
    my $CustomerAreaCode = $parser_ref->{CustomerAreaCode};

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

    #Is this an airport or heliport record with a blank subsection?
    if ( ( $SectionCode =~ m/[PH]/i ) && ( !$SubSectionCode ) ) {

        #If yes,  subsection codes are in a different place in airport and heliport records
        #Reparse and reset the variables
        $parser_ref = $parser_airportheliport->parse_newref($textOfCurrentLine);

        #Check for mismatch between expected and actual lengths
        if ( $parser_airportheliport->length != length($textOfCurrentLine) ) {
            die "Line # $currentLineNumber - Bad parse. Expected "
              . $parser_airportheliport->length
              . " characters but read "
              . length($textOfCurrentLine) . "\n";
        }

        $RecordType       = $parser_ref->{RecordType};
        $SectionCode      = $parser_ref->{SectionCode};
        $SubSectionCode   = $parser_ref->{SubSectionCode};
        $CustomerAreaCode = $parser_ref->{CustomerAreaCode};
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

    #Create an array to feed to Parse::FixedLength from the parser format we
    #looked up in the hash_of_parsers
    my @parserArray =
      split( ' ', $hash_of_parsers{$SectionCode}{$SubSectionCode} );

    #Create the specific parser for this section/subsection
    my $parser_specific =
      Parse::FixedLength->new( [@parserArray], \%parameters );

    #Basic sanity check for the parser
    die "Bad length on parser_specific" if ( $parser_specific->length != 132 );

    #Check for mismatch between expected and actual lengths
    if ( $parser_specific->length != length($textOfCurrentLine) ) {
        die "Line # $currentLineNumber - Bad parse. Expected "
          . $parser_specific->length
          . " characters but read "
          . length($textOfCurrentLine) . "\n";
    }

    # #Say what line of the source file we're working with and what section/subsection it is
    # say "Line # $. :"
    # . "$sections{$SectionCode}{$SubSectionCode}:"
    # . "$SectionCode$SubSectionCode";    #

    #Parse again with a more specific parser
    my $parser2_ref = $parser_specific->parse_newref($textOfCurrentLine);

    #Array of values
    # my  @ary      = $parser_specific->parse($textOfCurrentLine);
    # say @ary;
    #Reference to array of names
    my $parser_names_ref = $parser_specific->names;

    # say @$ary_ref;

    #------------------------------------------------
    # #This is temporary code to process and print out AS - MORA records
    # if ( $SectionCode eq "A" && $SubSectionCode eq "S" ) {
    # # say $textOfCurrentLine;
    # my $startingLatitude  = $parser2_ref->{StartingLatitude};
    # my $startingLongitude = $parser2_ref->{StartingLongitude};

    # # say "startingLatitude: $startingLatitude, startingLongitude: $startingLongitude";
    # for ( my $i = 1 ; $i <= 30 ; $i++ ) {

    # my $mora = $parser2_ref->{ "MORA_" . $i };

    # # say "MORA: " . $parser2_ref->{"MORA_" . $i}
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

    # # print Dumper($parser2_ref);
    # }
    #------------------------------------------------
    # #This is temporary code to print out runway records
    # if ( $SectionCode eq "P" && $SubSectionCode eq "G" ) {
    # #Have we already printed out the .csv header?
    # if ( $havePrintedKeys == 0 ) {
    # #Create these two keys for data we'll create in next step
    # $parser2_ref->{LatitudeDecimal}  = "";
    # $parser2_ref->{LongitudeDecimal} = "";
    # #Print the CSV header
    # foreach my $key ( sort keys $parser2_ref ) {
    # print $key . ",";
    # }
    # say "";
    # $havePrintedKeys = 1;
    # }
    # E15028000000
    # #Calculate the decimal equivalents for given lat/lon values and add to hash
    # $parser2_ref->{LatitudeDecimal} =
    # coordinateToDecimalCifpFormat( $parser2_ref->{RunwayLatitude} );
    # $parser2_ref->{LongitudeDecimal} =
    # coordinateToDecimalCifpFormat( $parser2_ref->{RunwayLongitude} );

    # #Print the values of each hash key, sorted so they correspond with headers printed earlier
    # foreach my $key ( sort keys $parser2_ref ) {
    # print $parser2_ref->{$key} . ",";
    # }
    # say "";
    # }

    #Work with continuation records

    if (   $parser2_ref->{ContinuationRecordNumber}
        && $parser2_ref->{ContinuationRecordNumber} > 2 )
    {
        say "Continuation record number greater than 2";
    }

    #This is meant to check that records that should have {ContinuationRecordNumber} defined actually do.
    if ( not defined $parser2_ref->{ContinuationRecordNumber} ) {
        say "No continuation number for this record";
        say
          "$datafile line # $. : SectionCode:$SectionCode and SubSectionCode:$SubSectionCode---";

        # say "$textOfCurrentLine";
    }

    #Is the next record a continuation record?
    elsif ( $parser2_ref->{ContinuationRecordNumber} eq '1' ) {

        # if ($debug) {
        #         say "Next record is a continuation record";
        # # print Dumper($parser2_ref);
        #         say $parser2_ref->{ContinuationRecordNumber};
        #         say $textOfCurrentLine;
        # }
    }

    #Is this record a continuation record?  If ContinuationRecordNumber > 1 (goes into A..Z too) then it is)
    elsif (( $parser2_ref->{ContinuationRecordNumber} ne '0' )
        && ( $parser2_ref->{ContinuationRecordNumber} ne '1' ) )
    {
        #         say "This record is a continuation record for $SectionCode-$SubSectionCode";
        #         say $parser2_ref->{ContinuationRecordNumber};
        #         say "$textOfCurrentLine";
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
            if ( $parser_continuation_base->length !=
                length($textOfCurrentLine) )
            {
                die "Line # $currentLineNumber - Bad parse. Expected "
                  . $parser_continuation_base->length
                  . " characters but read "
                  . length($textOfCurrentLine) . "\n";
            }

            #Parse the line with the base parser
            $parser2_ref =
              $parser_continuation_base->parse_newref($textOfCurrentLine);

            #Update the names of this new parser
            $parser_names_ref = $parser_continuation_base->names;

            # say "This record is a continuation record";
            # say
            # "$datafile line # $. : SectionCode:$SectionCode and SubSectionCode:$SubSectionCode---";

            #Pull out the application type
            $application = $parser2_ref->{ApplicationType};

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
                if ( $parser_continuation_application->length !=
                    length($textOfCurrentLine) )
                {
                    die "Line # $currentLineNumber - Bad parse. Expected "
                      . $parser_continuation_application->length
                      . " characters but read "
                      . length($textOfCurrentLine) . "\n";
                }

                #Parse again with a more specific parser
                $parser2_ref =
                  $parser_continuation_application->parse_newref(
                    $textOfCurrentLine);

                #Update the names of this new parser
                $parser_names_ref = $parser_continuation_application->names;
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

    #Add new columns for any latitude/longtitude
    #Convert the CIFP format longtitude/latitude to decimal WGS84
    for my $coordinateKey ( keys %{$parser2_ref} ) {
        my $value = $parser2_ref->{$coordinateKey};

        #Find any entry that ends in "latitude" or "longitude"
        if ( $coordinateKey =~ /(?:latitude|longitude)$/ix ) {
            my $wgs84_coordinate;

            #Add this new key name so it will get included during table creation
            push $parser_names_ref, $coordinateKey . '_WGS84';

            #Make sure at least a placeholder key is present
            $parser2_ref->{ $coordinateKey . '_WGS84' } = '';

            if ($value) {

                #Convert that value to WGS84 decimal
                $wgs84_coordinate = coordinateToDecimalCifpFormat($value);
            }

            #If the conversion succeeded update the new key with this calculated value
            if ($wgs84_coordinate) {
                $parser2_ref->{ $coordinateKey . '_WGS84' } = $wgs84_coordinate;
            }
        }
    }

    # #Add the raw text of this line in just for reference
    # $parser2_ref->{rawTextOfCurrentLine} = $textOfCurrentLine;

    #Delete any keys/columns with "BlankSpacing" in the name
    {
        my @unwanted;
        foreach my $key ( keys %{$parser2_ref} ) {
            if ( $key =~ /BlankSpacing/i ) {

                #Save this key to our array of entries to delete
                push @unwanted, $key;
            }
        }

        foreach my $key (@unwanted) {
            delete $parser2_ref->{$key};
        }

        #Delete any "BlankSpacing" columns from the parser sections list
        @$parser_names_ref = grep { $_ !~ /BlankSpacing/i } @$parser_names_ref;

        #         @$parser_names_ref
        #         my @del_indexes = reverse(grep { $arr[$_] =~ /BlankSpacing/i } 0..$#arr);
        #         foreach $item (@del_indexes) {
        #             splice (@arr,$item,1);
        #             }
    }

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

        #Makes a "CREATE TABLE" statement based on the keys of the hash
        # I'm trying two methods here, so only one "join" should be uncommented:
        # a) columns sorted alphabetically
        # b) Columns in the order they're defined in parser
        my $createStmt =
            'CREATE TABLE "'
          . $primary_or_continuation . "_"
          . $SectionCode . "_"
          . $SubSectionCode . "_"
          . $application . "_"
          . $sections{$SectionCode}{$SubSectionCode}
          . '" (_id INTEGER PRIMARY KEY AUTOINCREMENT,'

          #           . join( ',', sort { lc $a cmp lc $b } keys %{ $parser2_ref } ) . ')'
          . join( ',', @$parser_names_ref ) . ')';

        # Create the table
        say $createStmt . "\n";

        # say "";
        $dbh->do($createStmt);

        #Mark it as created so we don't try to create again
        $haveCreatedTable{$primary_or_continuation}{$SectionCode}
          {$SubSectionCode}{$application} = 1;
    }

    #-------------------
    #Make an "INSERT INTO" statement based on the keys and values of the hash
    #Relies on the fact that "keys" and "values" will always resolve in the same
    # order unless you modify the hash
    my $insertStmt =
        'INSERT INTO "'
      . $primary_or_continuation . "_"
      . $SectionCode . "_"
      . $SubSectionCode . "_"
      . $application . "_"
      . $sections{$SectionCode}{$SubSectionCode} . '" ('
      . join( ',', keys %{$parser2_ref} )
      . ') VALUES ('
      . join( ',', ('?') x keys %{$parser2_ref} ) . ')';

    #Insert the values into the database
    my $sth = $dbh->prepare($insertStmt);

    # my $sth = $dbh->prepare_cached($insertStmt);
    $sth->execute( values %{$parser2_ref} );

}
### Transaction commit...
$dbh->commit();

#Show what Sections and Subsections we found in this file
say "Types of records found in $datafile";
print Dumper( \%haveCreatedTable );
close($file);
exit;

sub coordinateToDecimalCifpFormat {

    #Convert a latitude or longitude in CIFP format to its decimal equivalent
    my ($coordinate) = shift;
    my ( $deg, $min, $sec, $signedDegrees, $declination, $secPostDecimal );
    my $parser_ref;

    #Get the length of this coordinate
    my $coordinate_length = length($coordinate);

    #Get the first character of the coordinate and parse accordingly
    $declination = substr( $coordinate, 0, 1 );

    given ($declination) {

        when (/[NS]/i) {
            my $parser_latitude;

            given ($coordinate_length) {
                when (3) {
                    $parser_latitude = Parse::FixedLength->new(
                        [
                            qw(
                              Declination:1
                              Degrees:2
                              )
                        ]
                    );
                }
                when (9) {
                    $parser_latitude = Parse::FixedLength->new(
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
                }

                when (11) {

                    # 5.267 High Precision Latitude (HPLAT)
                    # Definition/Description: The “High Precision Latitude”
                    # field contains the latitude of the navigation feature
                    # identified in the record.
                    # Source/Content: The content of field is an expansion of
                    # the latitude defined in Section 5.36 to include degrees,
                    # minutes, tenths, hundredths, thousandths and tenths of
                    # thousandths of seconds to accommodate the high
                    # precision resolution of 0.0005 arc seconds.
                    #
                    # Used On:Path Point Records
                    # Length:11 characters
                    # Character Type:Alpha/numeric
                    # Example:N3028422400
                    #                     say "High precision latitude: $coordinate";
                    $parser_latitude = Parse::FixedLength->new(
                        [
                            qw(
                              Declination:1
                              Degrees:2
                              Minutes:2
                              Seconds:2
                              SecondsPostDecimal:4
                              )
                        ]
                    );
                }
                default {
                    die "Bad input length on parser_latitude: $coordinate";
                }
            }

            $parser_ref = $parser_latitude->parse_newref($coordinate);

            #Latitude is invalid if less than -90  or greater than 90
            # $signedDegrees = "" if ( abs($signedDegrees) > 90 );
        }
        when (/[EW]/i) {
            my $parser_longitude;

            given ($coordinate_length) {
                when (4) {
                    $parser_longitude = Parse::FixedLength->new(
                        [
                            qw(
                              Declination:1
                              Degrees:3
                              )
                        ]
                    );
                }
                when (10) {
                    $parser_longitude = Parse::FixedLength->new(
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
                }

                when (12) {
                    #
                    # 5.268
                    # High Precision Longitude (HPLONG)
                    # Definition/Description: The “High Precision Longitude”
                    # field contains the latitude of the navigation feature
                    # identified in the record.
                    #
                    # Source/Content: The content of field is an expansion of
                    # the latitude defined in Section 5.36 to include degrees,
                    # minutes, tenths, hundredths, thousandths and tenths of
                    # thousandths of seconds to accommodate the high
                    # precision resolution of 0.0005 arc seconds.
                    #
                    # Used On:Path Point Records
                    # Length:12 characters
                    # Character Type:Alpha/numeric
                    # Example:W081420301000
                    #                     say "High precision longitude: $coordinate";
                    $parser_longitude = Parse::FixedLength->new(
                        [
                            qw(
                              Declination:1
                              Degrees:3
                              Minutes:2
                              Seconds:2
                              SecondsPostDecimal:4
                              )
                        ]
                    );
                }
                default {
                    die "Bad input length on parser_longitude: $coordinate";
                }
            }

            $parser_ref = $parser_longitude->parse_newref($coordinate);

            #Longitude is invalid if less than -180 or greater than 180
            # $signedDegrees = "" if ( abs($signedDegrees) > 180 );
        }
        default {
            say "Error on CifpCoordinate: $coordinate";
            return 0;

        }
    }

    $declination    = $parser_ref->{Declination};
    $deg            = $parser_ref->{Degrees};
    $min            = $parser_ref->{Minutes} //= 0;
    $sec            = $parser_ref->{Seconds} //= 0;
    $secPostDecimal = $parser_ref->{SecondsPostDecimal} //= 0;

    #     print Dumper($parser_ref);

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

sub usage {
    say "Usage: $0 -v -e -c<cycle> <directory containing FAACIFP18>\n";
    say "-v: enable debug output";
    say "-e: expand text";
    return;
}

