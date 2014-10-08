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

# use processFaaData;

use File::Basename;
use Getopt::Std;
use Parse::FixedLength;
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
use DBI;

use vars qw/ %opt /;

my $opt_string = 'vec:';

my $arg_num = scalar @ARGV;

unless ( getopts( "$opt_string", \%opt ) ) {
    say "Usage: $0 -v -e -c<cycle> <data directory>\n";
    say "-v: enable debug output";
    say "-e: expand text";
    exit(1);
}
if ( $arg_num < 1 ) {
    say "Usage: $0 -v -e <data directory>\n";
    say "-v: enable debug output";
    say "-e: expand text";
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
my $datafile = "$dir" . "FAACIFP18" . "-$cycle";

my $file;
open $file, '<', $datafile or die $!;



#Hash to hold whether we have already created table for this file and recordType
my %haveCreatedTable = ();

my %parameters = (
    'autonum' => 'true',

    # 'trim'    => 'true',
);

my %sections = (
    'A' => {
        'S' => 'MORA - Grid MORA'
    },
    'D' => {
        ''  => 'Navaid - VHF Navaid',
        'B' => 'Navaid - NDB Navaid',
    },
    'E' => {
        'A' => 'Enroute - Grid Waypoints',
        'M' => 'Enroute - Airway Markers',
        'P' => 'Enroute - Holding Patterns',
        'R' => 'Enroute - Airways and Routes',
        'T' => 'Enroute - Preferred Routes',
        'U' => 'Enroute - Airway Restrictions',
        'V' => 'Enroute - Airway Restrictions',
    },
    'H' => {
        'A' => 'Heliport - Pads',
        'C' => 'Heliport - Terminal Waypoints',
        'D' => 'Heliport - SIDs',
        'E' => 'Heliport - STARs',
        'F' => 'Heliport - Approach Procedures',
        'K' => 'Heliport - TAA',
        'S' => 'Heliport - MSA',
        'V' => 'Heliport - Communications',
    },
    'P' => {
        'A' => 'Airport - Reference Points',
        'B' => 'Airport - Gates',
        'C' => 'Airport - Terminal Waypoints',
        'D' => 'Airport - SIDs',
        'E' => 'Airport - STARs',
        'F' => 'Airport - Approach Procedures',
        'G' => 'Airport - Runways',
        'I' => 'Airport - Localizer/Glide Slope',
        'K' => 'Airport - TAA',
        'L' => 'Airport - MLS',
        'M' => 'Airport - Localizer Marker',
        'N' => 'Airport - Terminal NDB',
        'P' => 'Airport - Path Point',
        'R' => 'Airport - Flt Planning ARR/DEP',
        'S' => 'Airport - MSA',
        'T' => 'Airport - GLS Station',
        'V' => 'Airport - Communications',
    },
    'R' => {
        ''  => 'Company Routes - Company Routes',
        'A' => 'Company Routes - Alternate Records',

    },
    'T' => {
        'C' => 'Tables - Cruising Tables',
        'G' => 'Tables - Geographical Reference',
        'N' => 'Tables - RNAV Name Table',
    },
    'U' => {
        'C' => 'Airspace - Controlled Airspace',
        'F' => 'Airspace - FIR/UIR',
        'R' => 'Airspace - Restrictive Airspace',
    },
);

#These are parsers for each section/subsection combo we expect to find
#This is really the meat of the whole program
my %hash_of_parsers = (
    'A' => {
        'S' => 'RecordType:1
            BlankSpacing:3
            SectionCode:1
            SubSectionCode:1
            BlankSpacing:7
            StartingLatitude:3
            StartingLongitude:4
            BlankSpacing:10
            MORA:3
            MORA:3
            MORA:3
            MORA:3
            MORA:3
            MORA:3
            MORA:3
            MORA:3
            MORA:3
            MORA:3
            MORA:3
            MORA:3
            MORA:3
            MORA:3
            MORA:3
            MORA:3
            MORA:3
            MORA:3
            MORA:3
            MORA:3
            MORA:3
            MORA:3
            MORA:3
            MORA:3
            MORA:3
            MORA:3
            MORA:3
            MORA:3
            MORA:3
            MORA:3
            ReservedExpansion:3
            FileRecordNumber:5
            CycleDate:4
'
    },
    'D' => {
        '' => '
                RecordType:1
                CustomerAreaCode:3
                SectionCode:1
                SubSectionCode:1
                AirportICAOIdentifier:4
                ICAOCode:2
                BlankSpacing:1
                VORIdentifier:4
                BlankSpacing:2
                ICAOCode:2
                ContinuationRecordNumber:1
                VORFrequency:5
                NAVAIDClass:5
                VORLatitude:9
                VORLongitude:10
                DMEIdent:4
                DMELatitude:9
                DMELongitude:10
                StationDeclination:5
                DMEElevation:5
                FigureofMerit:1
                ILSDMEBias:2
                FrequencyProtection:3
                DatumCode:3
                VORName:30
                FileRecordNumber:5
                CycleDate:4
                ',
        'B' => '
                RecordType:1
                CustomerAreaCode:3
                SectionCode:1
                SubSectionCode:1
                AirportICAOIdentifier:4
                ICAOCode:2
                BlankSpacing:1
                NDBIdentifier:4
                BlankSpacing:2
                ICAOCode:2
                ContinuationRecordNumber:1
                NDBFrequency:5
                NDBClass:5
                NDBLatitude:9
                NDBLongitude:10
                BlankSpacing:23
                MagneticVariation:5
                BlankSpacing:6
                ReservedExpansion:5
                DatumCode:3
                NDBName:30
                FileRecordNumber:5
                CycleData:4 
                ',
    },

    'E' => {
        'A' => '
                RecordType:1
                CustomerAreaCode:3
                SectionCode:1
                SubSectionCode:1
                RegionCode:4
                ICAOCode:2
                Subsection:1
                WaypointIdentifier:5
                BlankSpacing:1
                ICAOCode:2
                ContinuationRecordNumber:1
                BlankSpacing:4
                WaypointType:3
                WaypointUsage:2
                BlankSpacing:1
                WaypointLatitude:9
                WaypointLongitude:10
                BlankSpacing:23
                DynamicMagVariation:5
                ReservedExpansion:5
                DatumCode:3
                ReservedExpansion:8
                NameFormatIndicator:3
                WaypointNameDescription:25
                FileRecordNumber:5
                CycleDate:4
                ',

        'M' => 'RecordType:1
                CustomerAreaCode:3
                SectionCode:1
                SubSectionCode:1
                BlankSpacing:7
                MarkerIdentifier:4
                BlankSpacing:2
                ICAOCode:2
                ContinuationRecordNumber:1
                MarkerCode:4
                ReservedExpansion:1
                MarkerShape:1
                MarkerPower:1
                BlankSpacing:3
                MarkerLatitude:9
                MarkerLongitude:10
                MinorAxis:4
                BlankSpacing:19
                MagneticVariation:5
                FacilityElevation:5
                DatumCode:3
                BlankSpacing:6
                MarkerName:30
                FileRecordNumber:5
                CycleDate:4
                ',
        'P' => '
            RecordType:1
            CustomerAreaCode:3
            SectionCode:1
            SubSectionCode:1
            RegionCode:4
            ICAOCode:2
            BlankSpacing:15
            DuplicateIdentifier:2
            FixIdentifier:5
            ICAOCode:2
            SectionCode:1
            SubSectionCode:1
            ContinuationRecordNumber:1
            InboundHoldingCourse:4
            TurnDirection:1
            LegLength:3
            LegTime:2
            MinimumAltitude:5
            MaximumAltitude:5
            HoldingSpeed:3
            RNP:3
            ArcRadius:6
            ReservedExpansion:27
            Name:25
            FileRecordNumber:5
            CycleDate:4
            ',
        'R' => 'RecordType:1
            CustomerAreaCode:3
            SectionCode:1
            SubSectionCode:1
            BlankSpacing:7
            RouteIdentifier:5
            Reserved:1
            BlankSpacing:6
            SequenceNumber:4
            FixIdentifier:5
            ICAOCode:2
            SectionCode:1
            Subsection:1
            ContinuationRecordNumber:1
            WaypointDescriptionCode:4
            BoundaryCode:1
            RouteType:1
            Level:1
            DirectionRestriction:1
            CruiseTableIndicator:2
            EUIndicator:1
            RecommendedNAVAID:4
            ICAOCode:2
            RNP:3
            BlankSpacing:3
            Theta:4
            Rho:4
            OutboundMagneticCourse:4
            RouteDistanceFrom:4
            InboundMagneticCourse:4
            BlankSpacing:1
            MinimumAltitude:5
            MinimumAltitude:5
            MaximumAltitude:5
            FixRadiusTransitionIndicator:3
            ReservedExpansion:22
            FileRecordNumber:5
            CycleDate:4
            ',

        'T' => 'RecordType:1
                CustomerAreaCode:3
                SectionCode:1
                SubSectionCode:1
                BlankSpacing:7
                RouteIdentifier:10
                PreferredRouteUseInd:2
                SequenceNumber:4
                BlankSpacing:9
                ContinuationRecordNumber:1
                ToFixIdentifier:5
                ICAOCode:2
                SectionCode:1
                SubSectionCode:1
                VIACode:3
                SIDSTARAWYIdent:6Note1
                AREACode:3
                Level:1
                RouteType:1
                InitialAirportFix:5
                ICAOCode:2
                SectionCode:1
                SubSectionCode:1
                TerminusAirportFix:5
                ICAOCode:2
                SectionCode:1
                SubSectionCode:1
                MinimumAltitude:5
                MaximumAltitude:5
                TimeCode:1
                AircraftUseGroup:2
                DirectionRestriction:1
                AltitudeDescription:1
                AltitudeOne:5
                AltitudeTwo:5
                ReservedExpansion:18
                FileRecordNumber:5
                CycleDate:4
                ',
        'U' => 'RecordType:1
                CustomerAreaCode:3
                SectionCode:1
                SubSectionCode:1
                RouteIdentifier:5
                Reserved:1
                RestrictionIdentifier:3
                RestrictionType:2
                ContinuationRecordNumber:1
                StartFixIdentifier:5
                StartFixICAOCode:2
                StartFixSectionCode:1
                StartFixSubSectionCode:1
                EndFixIdentifier:5
                EndFixICAOCode:2
                EndFixSectionCode:1
                EndFixSubSectionCode:1
                BlankSpacing:1
                StartDate:7
                EndDate:7
                TimeCode:1
                TimeIndicator:1
                TimeofOperation:10
                TimeofOperation:10
                TimeofOperation:10
                TimeofOperation:10
                ExclusionIndicator:1
                UnitsofAltitude:1
                RestrictionAltitude:3
                BlockIndicator:1
                RestrictionAltitude:3
                BlockIndicator:1
                RestrictionAltitude:3
                BlockIndicator:1
                RestrictionAltitude:3
                BlockIndicator:1
                RestrictionAltitude:3
                BlockIndicator:1
                RestrictionAltitude:3
                BlockIndicator:1
                RestrictionAltitude:3
                BlockIndicator:1
                FileRecordNumber:5
                CycleDate:4
                ',
        'V' => 'RecordType:1
                CustomerAreaCode:3
                SectionCode:1
                SubSectionCode:1
                FIRRDOIdent:4
                FIRUIRAddress:4
                Indicator:1
                ReservedExpansion:3
                RemoteName:25
                CommunicationsType:3
                CommFrequency:7
                GuardTransmit:1
                FrequencyUnits:1
                ContinuationRecordNumber:1
                ServiceIndicator:3
                RadarService:1
                Modulation:1
                SignalEmission:1
                Latitude:9
                Longitude:10
                MagneticVariation:5
                FacilityElevation:5
                H24Indicator:1
                AltitudeDescript:1
                CommunicationAltitude:5
                CommunicationAltitude:5
                RemoteFacility:4
                ICAOCode:2
                SectionCode:1
                SubSectionCode:1
                ReservedExpansion:12
                FileRecordNumber:5
                CycleDate:4
                ',
    },

    'H' => {

        # ''  => 'Remainder:132',
        'A' => 'RecordType:1
                            CustomerAreaCode:3
                            SectionCode:1
                            BlankSpacing:1
                            HeliportIdentifier:4
                            ICAOCode:2
                            SubSectionCode:1
                            ATAIATADesignator:3
                            PADIdentifier:5
                            ContinuationRecordNumber:1
                            SpeedLimitAltitude:5
                            DatumCode:3
                            IFRIndicator:1
                            BlankSpacing:1
                            Latitude:9
                            Longitude:10
                            MagneticVariation:5
                            HeliportElevation:5
                            SpeedLimit:3
                            RecommendedVHFNavaid:4
                            ICAOCode:2
                            TransitionAltitude:5
                            TransitionLevel:5
                            PublicMilitaryIndicator:1
                            TimeZone:3
                            DaylightIndicator:1
                            PadDimensions:6
                            MagneticTrueIndicator:1
                            ReservedExpansion:1
                            HeliportName:30
                            FileRecordNumber:5
                            CycleDate:4
                            ',
        'C' => 'RecordType:1
                        CustomerAreaCode:3
                        SectionCode:1
                        BlankSpacing:1
                        HeliportIdentifier:4
                        ICAOCode:2
                        SubSectionCode:1
                        WaypointIdentifier:5
                        BlankSpacing:1
                        ICAOCode:2
                        ContinuationRecordNumber:1
                        BlankSpacing:4
                        WaypointType:3
                        WaypointUsage:2
                        BlankSpacing:1
                        WaypointLatitude:9
                        WaypointLongitude:10
                        BlankSpacing:23
                        DynamicMagneticVariation:5
                        ReservedExpansion:5
                        DatumCode:3
                        ReservedExpansion:8
                        NameFormatIndicator:3
                        WaypointNameDescription:25
                        FileRecordNumber:5
                        CycleDate:4
                        ',
        'D' => 'RecordType:1
                        CustomerAreaCode:3
                        SectionCode:1
                        BlankSpacing:1
                        HeliportIdentifier:4
                        ICAOCode:2
                        SubSectionCode:1
                        SIDSTARAPPIdentifier:6
                        RouteType:1
                        TransitionIdentifier:5
                        BlankSpacing:1
                        SequenceNumber:3
                        FixIdentifier:5
                        ICAOCode:2
                        SectionCode:1
                        SubSectionCode:1
                        ContinuationRecordNumber:1
                        WaypointDescriptionCode:4
                        TurnDirection:1
                        RNP:3
                        PathAndTermination:2
                        TurnDirectionValid:1
                        RecommendedNavaid:4
                        ICAOCode:2
                        ARCRadius:6
                        Theta:4
                        Rho:4
                        MagneticCourse:4
                        RouteDistanceHoldingDistanceOrTime:4
                        RecommendedNavaidSection:1
                        RecommendedNavaidSubsection:1
                        ReservedSpacing:2
                        AltitudeDescription:1
                        ATCIndicator:1
                        Altitude:5
                        Altitude:5
                        TransitionAltitude:5
                        SpeedLimit:3
                        VerticalAngle:4
                        CenterFixOrTAAProcedureTurnIndicator:5
                        MultipleCodeOrTAASectorIdentifier:1
                        ICAOCode:2
                        SectionCode:1
                        SubSectionCode:1
                        GNSSFMSIndicator:1
                        SpeedLimitDescription:1
                        ApchRouteQualifier1:1
                        ApchRouteQualifier2:1
                        BlankSpacing:3
                        FileRecordNumber:5
                        CycleDate:4
                        ',
        'E' => 'RecordType:1
                        CustomerAreaCode:3
                        SectionCode:1
                        BlankSpacing:1
                        HeliportIdentifier:4
                        ICAOCode:2
                        SubSectionCode:1
                        SIDSTARAPPIdentifier:6
                        RouteType:1
                        TransitionIdentifier:5
                        BlankSpacing:1
                        SequenceNumber:3
                        FixIdentifier:5
                        ICAOCode:2
                        SectionCode:1
                        SubSectionCode:1
                        ContinuationRecordNumber:1
                        WaypointDescriptionCode:4
                        TurnDirection:1
                        RNP:3
                        PathAndTermination:2
                        TurnDirectionValid:1
                        RecommendedNavaid:4
                        ICAOCode:2
                        ARCRadius:6
                        Theta:4
                        Rho:4
                        MagneticCourse:4
                        RouteDistanceHoldingDistanceOrTime:4
                        RecommendedNavaidSection:1
                        RecommendedNavaidSubsection:1
                        ReservedSpacing:2
                        AltitudeDescription:1
                        ATCIndicator:1
                        Altitude:5
                        Altitude:5
                        TransitionAltitude:5
                        SpeedLimit:3
                        VerticalAngle:4
                        CenterFixOrTAAProcedureTurnIndicator:5
                        MultipleCodeOrTAASectorIdentifier:1
                        ICAOCode:2
                        SectionCode:1
                        SubSectionCode:1
                        GNSSFMSIndicator:1
                        SpeedLimitDescription:1
                        ApchRouteQualifier1:1
                        ApchRouteQualifier2:1
                        BlankSpacing:3
                        FileRecordNumber:5
                        CycleDate:4
                        ',
        'F' => 'RecordType:1
                        CustomerAreaCode:3
                        SectionCode:1
                        BlankSpacing:1
                        HeliportIdentifier:4
                        ICAOCode:2
                        SubSectionCode:1
                        SIDSTARAPPIdentifier:6
                        RouteType:1
                        TransitionIdentifier:5
                        BlankSpacing:1
                        SequenceNumber:3
                        FixIdentifier:5
                        ICAOCode:2
                        SectionCode:1
                        SubSectionCode:1
                        ContinuationRecordNumber:1
                        WaypointDescriptionCode:4
                        TurnDirection:1
                        RNP:3
                        PathAndTermination:2
                        TurnDirectionValid:1
                        RecommendedNavaid:4
                        ICAOCode:2
                        ARCRadius:6
                        Theta:4
                        Rho:4
                        MagneticCourse:4
                        RouteDistanceHoldingDistanceOrTime:4
                        RecommendedNavaidSection:1
                        RecommendedNavaidSubsection:1
                        ReservedSpacing:2
                        AltitudeDescription:1
                        ATCIndicator:1
                        Altitude:5
                        Altitude:5
                        TransitionAltitude:5
                        SpeedLimit:3
                        VerticalAngle:4
                        CenterFixOrTAAProcedureTurnIndicator:5
                        MultipleCodeOrTAASectorIdentifier:1
                        ICAOCode:2
                        SectionCode:1
                        SubSectionCode:1
                        GNSSFMSIndicator:1
                        SpeedLimitDescription:1
                        ApchRouteQualifier1:1
                        ApchRouteQualifier2:1
                        BlankSpacing:3
                        FileRecordNumber:5
                        CycleDate:4
                        ',
        'K' => 'RecordType:1
                        CustomerAreaCode:3
                        SectionCode:1
                        BlankSpacing:1
                        HeliportIdentifier:4
                        ICAOCode:2
                        SubSectionCode:1
                        ApproachIdentifier:6
                        SectionCode:1
                        TAASectorIdentifier:1
                        TAAProcedureTurn:4
                        BlankReserved:5
                        TAAIAFWaypoint:5
                        ICAOCode:2
                        SectionCode:1
                        SubSectionCode:1
                        ContinuationRecordNumber:1
                        Reserved:1
                        MagTrueIndicator
                        SectorRadius1:4
                        SectorBearing:6
                        SectorMinimumAltitude:3
                        SectorRadius1:4
                        SectorBearing:6
                        SectorMinimumAltitude:3
                        SectorRadius1:4
                        SectorBearing:6
                        SectorMinimumAltitude:3
                        SectorRadius1:4
                        SectorBearing:6
                        SectorMinimumAltitude:3
                        SectorRadius1:4
                        SectorBearing:6
                        SectorMinimumAltitude:3
                        SectorRadius1:4
                        SectorBearing:6
                        SectorMinimumAltitude:3
                        BlankSpacing:4
                        FileRecordNumber:5
                        CycleDate:4
                        ',
        'S' => 'RecordType:1
                        CustomerAreaCode:3
                        SectionCode:1
                        BlankSpacing:1
                        HeliportIdentifier:4
                        ICAOCode:2
                        SubSectionCode:1
                        MSACenter:5
                        ICAOCode:2
                        SectionCode:1
                        SubSectionCode:1
                        MultipleCode:1
                        ReservedExpansion:15
                        ContinuationRecordNumber:1
                        ReservedSpacing:3
                        SectorBearing:6
                        SectorAltitude:3
                        SectorRadius:2
                        SectorBearing:6
                        SectorAltitude:3
                        SectorRadius:2
                        SectorBearing:6
                        SectorAltitude:3
                        SectorRadius:2
                        SectorBearing:6
                        SectorAltitude:3
                        SectorRadius:2
                        SectorBearing:6
                        SectorAltitude:3
                        SectorRadius:2
                        SectorBearing:6
                        SectorAltitude:3
                        SectorRadius:2
                        SectorBearing:6
                        SectorAltitude:3
                        SectorRadius:2
                        MagneticTrueIndicator:1
                        ReservedExpansion:3
                        FileRecordNumber:5
                        CycleDate:4
                        ',
        'V' => 'RecordType:1
                CustomerAreaCode:3
                SectionCode:1
                BlankSpacing:1
                HeliportIdentifier:4
                ICAOCode:2
                SubSectionCode:1
                CommunicationsType:3
                CommunicationsFreq:7
                GuardTransmit:1
                FrequencyUnits:1
                ContinuationRecordNumber:1
                ServiceIndicator:3
                RadarService:1
                Modulation:1
                SignalEmission:1
                Latitude:9
                Longitude:10
                MagneticVariation:5
                FacilityElevation:5
                H24Indicator:1
                Sectorization:6
                AltitudeDescription:1
                CommunicationAltitude:5
                CommunicationAltitude:5
                SectorFacility:4
                ICAOCode:2
                SectionCode:1
                SubSectionCode:1
                DistanceDescription:1
                CommunicationsDistance:2
                RemoteFacility:4
                ICAOCode:2
                SectionCode:1
                SubSectionCode:1
                CallSign:25
                FileRecordNumber:5
                CycleDate:4
                ',
    },
    'P' => {

        # ''  => 'Remainder:132',
        'A' => 'RecordType:1
                CustomerAreaCode:3
                SectionCode:1
                BlankSpacing:1
                AirportICAOIdentifier:4
                ICAOCode:2
                SubSectionCode:1
                ATAIATADesignator:3
                ReservedExpansion:2
                BlankSpacing:3
                ContinuationRecordNumber:1
                SpeedLimitAltitude:5
                LongestRunway:3
                IFRCapability:1
                LongestRunwaySurfaceCode:1
                AirportReferencePtLatitude:9
                AirportReferencePtLongitude:10
                MagneticVariation:5
                AirportElevation:5
                SpeedLimit:3
                RecommendedNavaid:4
                ICAOCode:2
                TransitionsAltitude:5
                TransitionLevel:5
                PublicMilitaryIndicator:1
                TimeZone:3
                DaylightIndicator:1
                MagneticTrueIndicator:1
                DatumCode:3
                ReservedExpansion:4
                AirportName:30
                FileRecordNumber:5
                CycleDate:4
                ',

        'B' => 'RecordType:1
                CustomerAreaCode:3
                SectionCode:1
                BlankSpacing:1
                AirportICAOIdentifier:4
                ICAOCode:2
                SubSectionCode:1
                GateIdentifier:5
                BlankSpacing:3
                ContinuationRecordNumber:1
                BlankSpacing:10
                GateLatitude:9
                GateLongitude:10
                ReservedExpansion:47
                Name:25
                FileRecordNumber:5
                CycleDate:4
                ',

        'C' => 'RecordType:1
                CustomerAreaCode:3
                SectionCode:1
                SubSectionCode:1
                RegionCode:4
                ICAOCode:2
                Subsection:1
                WaypointIdentifier:5
                BlankSpacing:1
                ICAOCode:2
                ContinuationRecordNumber:1
                BlankSpacing:4
                WaypointType:3
                WaypointUsage:2
                BlankSpacing:1
                WaypointLatitude:9
                WaypointLongitude:10
                BlankSpacing:23
                DynamicMagVariation:5
                ReservedExpansion:5
                DatumCode:3
                ReservedExpansion:8
                NameFormatIndicator:3
                WaypointNameDescription:25
                FileRecordNumber:5
                CycleDate:4
                ',
        'D' => 'RecordType:1
                CustomerAreaCode:3
                SectionCode:1
                BlankSpacing:1
                AirportIdentifier:4
                ICAOCode:2
                SubSectionCode:1
                SIDSTARApproachIdentifier:6
                RouteType:1
                TransitionIdentifier:5
                BlankSpacing:1
                SequenceNumber:3
                FixIdentifier:5
                ICAOCode:2
                SectionCode:1
                SubSectionCode:1
                ContinuationRecordNumber:1
                WaypointDescriptionCode:4
                TurnDirection:1
                RNP:3
                PathAndTermination:2
                TurnDirectionValid:1
                RecommendedNavaid:4
                ICAOCode:2
                ARCRadius:6
                Theta:4
                Rho:4
                MagneticCourse:4
                RouteDistanceHoldingDistanceOrTime:4
                RECDNAVSection:1
                RECDNAVSubsection:1
                Reservedexpansion:2
                AltitudeDescription:1
                ATCIndicator:1
                Altitude:5
                Altitude:5
                TransitionAltitude:5
                SpeedLimit:3
                VerticalAngle:4
                CenterFixOrTAAProcedureTurnIndicator:5
                MultipleCodeOrTAASectorIdentifier:1
                ICAOCode:2
                SectionCode:1
                SubSectionCode:1
                GNSSFMSIndication:1
                SpeedLimitDescription:1
                ApchRouteQualifier1:1
                ApchRouteQualifier2:1
                BlankSpacing:3
                FileRecordNumber:5
                CycleDate:4
                ',
        'E' => 'RecordType:1
                CustomerAreaCode:3
                SectionCode:1
                BlankSpacing:1
                AirportIdentifier:4
                ICAOCode:2
                SubSectionCode:1
                SIDSTARApproachIdentifier:6
                RouteType:1
                TransitionIdentifier:5
                BlankSpacing:1
                SequenceNumber:3
                FixIdentifier:5
                ICAOCode:2
                SectionCode:1
                SubSectionCode:1
                ContinuationRecordNumber:1
                WaypointDescriptionCode:4
                TurnDirection:1
                RNP:3
                PathAndTermination:2
                TurnDirectionValid:1
                RecommendedNavaid:4
                ICAOCode:2
                ARCRadius:6
                Theta:4
                Rho:4
                MagneticCourse:4
                RouteDistanceHoldingDistanceOrTime:4
                RECDNAVSection:1
                RECDNAVSubsection:1
                Reservedexpansion:2
                AltitudeDescription:1
                ATCIndicator:1
                Altitude:5
                Altitude:5
                TransitionAltitude:5
                SpeedLimit:3
                VerticalAngle:4
                CenterFixOrTAAProcedureTurnIndicator:5
                MultipleCodeOrTAASectorIdentifier:1
                ICAOCode:2
                SectionCode:1
                SubSectionCode:1
                GNSSFMSIndication:1
                SpeedLimitDescription:1
                ApchRouteQualifier1:1
                ApchRouteQualifier2:1
                BlankSpacing:3
                FileRecordNumber:5
                CycleDate:4
                ',
        'F' => 'RecordType:1
                CustomerAreaCode:3
                SectionCode:1
                BlankSpacing:1
                AirportIdentifier:4
                ICAOCode:2
                SubSectionCode:1
                SIDSTARApproachIdentifier:6
                RouteType:1
                TransitionIdentifier:5
                BlankSpacing:1
                SequenceNumber:3
                FixIdentifier:5
                ICAOCode:2
                SectionCode:1
                SubSectionCode:1
                ContinuationRecordNumber:1
                WaypointDescriptionCode:4
                TurnDirection:1
                RNP:3
                PathAndTermination:2
                TurnDirectionValid:1
                RecommendedNavaid:4
                ICAOCode:2
                ARCRadius:6
                Theta:4
                Rho:4
                MagneticCourse:4
                RouteDistanceHoldingDistanceOrTime:4
                RECDNAVSection:1
                RECDNAVSubsection:1
                Reservedexpansion:2
                AltitudeDescription:1
                ATCIndicator:1
                Altitude:5
                Altitude:5
                TransitionAltitude:5
                SpeedLimit:3
                VerticalAngle:4
                CenterFixOrTAAProcedureTurnIndicator:5
                MultipleCodeOrTAASectorIdentifier:1
                ICAOCode:2
                SectionCode:1
                SubSectionCode:1
                GNSSFMSIndication:1
                SpeedLimitDescription:1
                ApchRouteQualifier1:1
                ApchRouteQualifier2:1
                BlankSpacing:3
                FileRecordNumber:5
                CycleDate:4
                ',
        'G' => 'RecordType:1
                CustomerAreaCode:3
                SectionCode:1
                BlankSpacing:1
                AirportICAOIdentifier:4
                ICAOCode:2
                SubSectionCode:1
                RunwayIdentifier:5
                BlankSpacing:3
                ContinuationRecordNumber:1
                RunwayLength:5
                RunwayMagneticBearing:4
                BlankSpacing:1
                RunwayLatitude:9
                RunwayLongitude:10
                RunwayGradient:5
                BlankSpacing:4
                LTPEllipsoidHeight:6
                LandingThresholdElevation:5
                DisplacedThresholdDistance:4
                ThresholdCrossingHeight:2
                RunwayWidth:3
                TCHValueIndicator:1
                LocalizerMLSGLSRefPathIdentifier:4
                LocalizerMLSGLSCategoryClass:1
                Stopway:4
                SecondLocalizerMLSGLSRefPathIdent:4
                SecondLocalizerMLSGLSCategoryClass:1
                ReservedExpansion:6
                RunwayDescription:22
                FileRecordNumber:5
                CycleDate:4
            ',
        'I' => 'RecordType:1
                CustomerAreaCode:3
                SectionCode:1
                BlankSpacing:1
                AirportIdentifier:4
                ICAOCode:2
                SubSectionCode:1
                LocalizerIdentifier:4
                ILSCategory:1
                BlankSpacing:3
                ContinuationRecordNumber:1
                LocalizerFrequency:5
                RunwayIdentifier:5
                LocalizerLatitude:9
                LocalizerLongitude:10
                LocalizerBearing:4
                GlideSlopeLatitude:9
                GlideSlopeLongitude:10
                LocalizerPosition:4
                LocalizerPositionReference:1
                GlideSlopePosition:4
                LocalizerWidth:4
                GlideSlopeAngle:3
                StationDeclination:5
                GlideSlopeHeightatLandingThreshold:2
                GlideSlopeElevation:5
                SupportingFacilityID:4
                SupportingFacilityICAOCode:2
                SupportingFacilitySectionCode:1
                SupportingFacilitySubSectionCode:1
                ReservedExpansion:13
                FileRecordNumber:5
                CycleDate:4',

        'K' => 'RecordType:1
                CustomerAreaCode:3
                SectionCode:1
                BlankSpacing:1
                AirportIdentifier:4
                ICAOCode:2
                SubSectionCode:1
                ApproachIdentifier:6
                TAASectorIdentifier:1
                TAAProcedureTurn:4
                BlankReserved:5
                TAAIAFWaypoint:5
                ICAOCode:2
                SectionCode:1
                SubSectionCode:1
                ContinuationRecordNumber:1
                Reserved:1
                MagTrueIndicator
                SectorRadius1:4
                SectorBearing:6
                SectorMinimumAltitude:3
                SectorRadius1:4
                SectorBearing:6
                SectorMinimumAltitude:3
                SectorRadius1:4
                SectorBearing:6
                SectorMinimumAltitude:3
                SectorRadius1:4
                SectorBearing:6
                SectorMinimumAltitude:3
                SectorRadius1:4
                SectorBearing:6
                SectorMinimumAltitude:3
                SectorRadius1:4
                SectorBearing:6
                SectorMinimumAltitude:3
                BlankSpacing:4
                FileRecordNumber:5
                CycleDate:4
                ',
        'L' => 'RecordType:1
                CustomerAreaCode:3
                SectionCode:1
                BlankSpacing:1
                AirportIdentifier:4
                ICAOCode:2
                SubSectionCode:1
                MLSIdentifier:4
                MLSCategory:1
                BlankSpacing:3
                ContinuationRecordNumber:1
                Channel:3
                BlankSpacing:2
                RunwayIdentifier:5
                AzimuthLatitude:9
                AzimuthLongitude:10
                AzimuthBearing:4
                ElevationLatitude:9
                ElevationLongitude:10
                AzimuthPosition:4
                AzimuthPositionReference:1
                ElevationPosition:4
                AzimuthProportionalAngleRight:3
                AzimuthProportionalAngleLeft:3
                AzimuthCoverageRight:3
                AzimuthCoverageLeft:3
                ElevationAngleSpan:3
                MagneticVariation:5
                ELElevation:5
                NominalElevationAngle:4
                MinimumGlidePathAngle:3
                SupportingFacilityIdentifier:4
                SupportingFacilityICAOCode:2
                SupportingFacilitySectionCode:1
                SupportingFacilitySubSectionCode:1
                FileRecordNumber:5
                CycleDate:4
                ',
        'M' => 'RecordType:1
                CustomerAreaCode:3
                SectionCode:1
                BlankSpacing:1
                AirportIdentifier:4
                ICAOCode:2
                SubSectionCode:1
                LocalizerIdentifier:4
                MarkerType:3
                BlankSpacing:1
                ContinuationRecordNumber:1
                LocatorFrequency:5
                RunwayIdentifier:5
                MarkerLatitude:9
                MarkerLongitude:10
                MinorAxisBearing:4
                LocatorLatitude:9
                LocatorLongitude:10
                LocatorClass:5
                LocatorFacilityCharacteristics:5
                LocatorIdentifier:4
                BlankSpacing:2
                MagneticVariation:5
                BlankSpacing:2
                FacilityElevation:5
                ReservedExpansion:21
                FileRecordNumber:5
                CycleDate:4
                ',
        'N' => ' RecordType:1
                CustomerAreaCode:3
                SectionCode:1
                SubSectionCode:1
                AirportICAOIdentifier:4
                ICAOCode:2
                BlankSpacing:1
                NDBIdentifier:4
                BlankSpacing:2
                ICAOCode:2
                ContinuationRecordNumber:1
                NDBFrequency:5
                NDBClass:5
                NDBLatitude:9
                NDBLongitude:10
                BlankSpacing:23
                MagneticVariation:5
                BlankSpacing:6
                ReservedExpansion:5
                DatumCode:3
                NDBName:30
                FileRecordNumber:5
                CycleData:4',

        'P' => 'RecordType:1
                CustomerAreaCode:3
                SectionCode:1
                Blank:1
                AirportIdentifier:4
                ICAOCode:2
                SubSectionCode:1
                ApproachProcedureIdent:6
                RunwayOrHelipadIdentifier:5
                OperationType:2
                ContinuationRecordNumber:1
                RouteIndicator:1
                SBASServiceProviderIdentifier:2
                ReferencePathDataSelector:2
                ReferencePathIdentifier:4
                ApproachPerformanceDesignator:1
                LandingThresholdPointLatitude:11
                LandingThresholdPointLongitude:12
                LTPEllipsoidHeight:6
                GlidePathAngle:4
                FlightPathAlignmentPointLatitude:11
                FlightPathAlignmentPointLongitude:12
                CourseWidthatThreshold:5
                LengthOffset:4
                PathPointTCH:6
                TCHUnitsIndicator:1
                HAL:3
                VAL:3
                SBASFASDataCRCRemainder:8
                FileRecordNumber:5
                CycleDate:4
                ',
        'R' => 'RecordType:1
                CustomerAreaCode:3
                SectionCode:1
                BlankSpacing:1
                AirportIdentifier:4
                ICAOCode:2
                SubSectionCode:1
                SIDSTARApproachIdentifier:6
                ProcedureType:1
                RunwayTransitionIdentifier:5
                RunwayTransitionFix:5
                ICAOCode:2
                SectionCode:1
                SubSectionCode:1
                RunwayTransitionAlongTrack
                Distance:3
                CommonSegmentTransitionFix:5
                ICAOCode:2
                SectionCode:1
                SubSectionCode:1
                CommonSegmentAlongTrack
                Distance:3
                EnrouteTransitionIdentifier:5
                EnrouteTransitionFix:5
                ICAOCode:2
                SectionCode:1
                SubSectionCode:1
                EnrouteTransitionAlongTrack
                Distance:3
                SequenceNumber:3
                ContinuationRecordNumber:1
                NumberofEngines:4
                TurbopropJetIndicator:1
                RNAVFlag:1
                ATCWeightCategory:1
                ATCIdentifier:7
                TimeCode:1
                ProcedureDescription:15
                LegTypeCode:2
                ReportingCode:1
                InitialDepartureMagneticCourse:4
                AltitudeDescription:1
                Altitude:3
                Altitude:3
                SpeedLimit:3
                InitialCruiseTable:2
                SpeedLimitDescription:1
                BlankSpacing:3
                FileRecordNumber:5
                CycleDate:4
                ',
        'S' => 'RecordType:1
                CustomerAreaCode:3
                SectionCode:1
                BlankSpacing:1
                AirportIdentifier:4
                ICAOCode:2
                SubSectionCode:1
                MSACenter:5
                ICAOCode:2
                SectionCode:1
                SubSectionCode:1
                MultipleCode:1
                ReservedExpansion:15
                ContinuationRecordNumber:1
                ReservedSpacing:3
                SectorBearing:6
                SectorAltitude:3
                SectorRadius:2
                SectorBearing:6
                SectorAltitude:3
                SectorRadius:2
                SectorBearing:6
                SectorAltitude:3
                SectorRadius:2
                SectorBearing:6
                SectorAltitude:3
                SectorRadius:2
                SectorBearing:6
                SectorAltitude:3
                SectorRadius:2
                SectorBearing:6
                SectorAltitude:3
                SectorRadius:2
                SectorBearing:6
                SectorAltitude:3
                SectorRadius:2
                MagneticTrueIndicator:1
                ReservedExpansion:3
                FileRecordNumber:5
                CycleDate:4
                ',

        'T' => 'RecordType:1
                CustomerAreaCode:3
                SectionCode:1
                Blank:1
                AirportorHeliportIdentifier:4
                ICAOCode:2
                SubSectionCode:1
                GLSRefPathIdentifier:4
                GLSCategory:1
                Blank:3
                ContinuationRecordNumber:1
                GLSChannel:5
                RunwayIdentifier:5
                Blank:19
                GLSApproachBearing:4Note1
                StationLatitude:9
                StationLongitude:10
                GLSStationident:4
                Blank:5
                ServiceVolumeRadius:2
                TDMASlots:2
                GLSApproachSlope:3
                MagneticVariation:5
                Reserved:2
                StationElevation:5
                DatumCode:3
                StationType:3
                Blank:2
                StationElevationWGS84:5
                Blank:8
                FileRecordNumber:5
                CycleDate:4
                ',
        'V' => 'RecordType:1
                CustomerAreaCode:3
                SectionCode:1
                BlankSpacing:1
                AirportIdentifier:4
                ICAOCode:2
                SubSectionCode:1
                CommunicationsType:3
                CommunicationsFreq:7
                GuardTransmit:1
                FrequencyUnits:1
                ContinuationRecordNumber:1
                ServiceIndicator:3
                RadarService:1
                Modulation:1
                SignalEmission:1
                Latitude:9
                Longitude:10
                MagneticVariation:5
                FacilityElevation:5
                H24Indicator:1
                Sectorization:6
                AltitudeDescription:1
                CommunicationAltitude:5
                CommunicationAltitude:5
                SectorFacility:4
                ICAOCode:2
                SectionCode:1
                SubSectionCode:1
                DistanceDescription:1
                CommunicationsDistance:2
                RemoteFacility:4
                ICAOCode:2
                SectionCode:1
                SubSectionCode:1
                CallSign:25
                FileRecordNumber:5
                CycleDate:4
                ',
    },
    'R' => {

        # '' => 'Remainder:132',
        'A' => 'RecordType:1
                CustomerAreaCode:3
                SectionCode:1
                SubSectionCode:1
                AlternateRelatedAirportOrFix:5
                AlternateRelatedICAOCode:2
                AlternateRelatedSectionCode:1
                AlternateRelatedSubSectionCode:1
                AlternateRecordType:2
                BlankSpacing:2
                DistancetoAlternate:3
                AlternateType:1
                PrimaryAlternateIdentifier:10
                BlankSpacing:2
                DistancetoAlternate:3
                AlternateType:1
                AdditionalAlternateIdentifierOne:10
                BlankSpacing:2
                DistancetoAlternate:3
                AlternateType:1
                AdditionalAlternateIdentifierTwo:10
                BlankSpacing:2
                DistancetoAlternate:3
                AlternateType:1
                AdditionalAlternateIdentifierThree:10
                BlankSpacing:2
                DistancetoAlternate:3
                AlternateType:1
                AdditionalAlternateIdentifierFour:10
                BlankSpacing:2
                DistancetoAlternate:3
                AlternateType:1
                AdditionalAlternateIdentifierFive:10
                Reservedexpansion:10
                FileRecordNumber:5
                CycleDate:4
                ',
    },
    'T' => {

        'C' => 'RecordType:1
                BlankSpacing:3
                SectionCode:1
                SubsectionCode:1
                CruiseTableIdentifier:2
                SequenceNumber:1
                BlankSpacing:19
                CourseFrom:4
                CourseTo:4
                MagTrue:1
                BlankSpacing:2
                CruiseLevelFrom:5
                VerticalSeparation:5
                CruiseLevelTo:5
                CruiseLevelFrom:5
                VerticalSeparation:5
                CruiseLevelTo:5
                CruiseLevelFrom:5
                VerticalSeparation:5
                CruiseLevelTo:5
                CruiseLevelFrom:5
                VerticalSeparation:5
                CruiseLevelTo:5
                ReservedExpansion:24
                FileRecordNumber:5
                CycleDate:4
                ',
        'G' => 'RecordType:1
                CustomerAreaCode:3
                SectionCode:1
                SubSectionCode:1
                GeographicalRefTableID:2
                SequenceNumber:1
                GeographicalEntity:29
                ContinuationRecordNumber:1
                Reserved:1
                PreferredRouteIdent:10
                PreferredRouteUseInd:2
                PreferredRouteIdent:10
                PreferredRouteUseInd:2
                PreferredRouteIdent:10
                PreferredRouteUseIndi:2
                PreferredRouteIdent:10
                PreferredRouteUseIndi:2
                PreferredRouteIdent:10
                PreferredRouteUseIndi:2
                PreferredRouteIdent:10
                PreferredRouteUseInd:2
                BlankSpacing:11
                FileRecordNumber:5
                CycleDate:4
                ',

        # 'N' => '                ',
    },
    'U' => {
        'C' => 'RecordType:1
            CustomerAreaCode:3
            SectionCode:1
            SubSectionCode:1
            ICAOCode:2
            AirspaceType:1
            AirspaceCenter:5
            SectionCode:1
            SubSectionCode:1
            AirspaceClassification:1
            ReservedSpacing:2
            MultipleCode:1
            SequenceNumber:4
            ContinuationRecordNumber:1
            Level:1
            TimeCode:1
            NOTAM:1
            BlankSpacing:2
            BoundaryVia:2
            Latitude:9
            Longitude:10
            ArcOriginLatitude:9
            ArcOriginLongitude:10
            ArcDistance:4
            ArcBearing:4
            RNP:3
            LowerLimit:5
            UnitIndicator:1
            UpperLimit:5
            UnitIndicator:1
            ControlledAirspaceName:30
            FileRecordNumber:5
            CycleDate:4
            ',

        'F' => 'RecordType:1
                CustomerAreaCode:3
                SectionCode:1
                SubSectionCode:1
                FIRUIRIdentifier:4
                FIRUIRAddress:4
                FIRUIRIndicator:1
                SequenceNumber:4
                ContinuationRecordNumber:1
                AdjacentFIRIdentifier:4
                AdjacentUIRIdentifier:4
                ReportingUnitsSpeed:1
                ReportingUnitsAltitude:1
                EntryReport:1
                BlankSpacing:1
                BoundaryVia:2
                FIRUIRLatitude:9
                FIRUIRLongitude:10
                ArcOriginLatitude:9
                ArcOriginLongitude:10
                ArcDistance:4
                ArcBearing:4
                FIRUpperLimit:5
                UIRLowerLimit:5
                UIRUpperLimit:5
                CruiseTableInd:2
                ReservedExpansion:1
                FIRUIRName:25
                FileRecordNumber:5
                CycleDate:4
                ',
        'R' => 'RecordType:1
            CustomerAreaCode:3
            SectionCode:1
            SubSectionCode:1
            ICAOCode:2
            RestrictiveType:1
            RestrictiveAirspaceDesignation:10
            MultipleCode:1
            SequenceNumber:4
            ContinuationRecordNumber:1
            Level:1
            TimeCode:1
            NOTAM:1
            BlankSpacing:2
            BoundaryVia:2
            Latitude:9
            Longitude:10
            ArcOriginLatitude:9
            ArcOriginLongitude:10
            ArcDistance:4
            ArcBearing:4
            BlankSpacing:3
            LowerLimit:5
            UnitIndicator:1
            UpperLimit:5
            UnitIndicator:1
            RestrictiveAirspaceName:30
            FileRecordNumber:5
            CycleDate:4
            ',
    },
);

#Use these parsers for continuation records
my %hash_of_continuation_base_parsers = (
    'A' => {

        # 'S' => {}
    },
    'D' => {

        # '' => {
        # '   ' => 'Navaid - VHF Navaid',
        # },

        # 'B' => {
        # 'XX' => 'Navaid - NDB Navaid',
    },
    'E' => {

        # 'A' => 'Enroute - Grid Waypoints',
        # 'M' => 'Enroute - Airway Markers',
        # 'P' => 'Enroute - Holding Patterns',
        # 'R' => 'Enroute - Airways and Routes',
        # 'T' => 'Enroute - Preferred Routes',
        # 'U' => 'Enroute - Airway Restrictions',
        # 'V' => 'Enroute - Airway Restrictions',
    },
    'H' => {

        # 'A' => 'Heliport - Pads',
        # 'C' => 'Heliport - Terminal Waypoints',
        # 'D' => 'Heliport - SIDs',
        # 'E' => 'Heliport - STARs',
        # 'F' => 'Heliport - Approach Procedures',
        # 'K' => 'Heliport - TAA',
        # 'S' => 'Heliport - MSA',
        # 'V' => 'Heliport - Communications',
    },

    #Airport
    'P' => {

        # 'A' => 'Airport - Reference Points',
        # 'B' => 'Airport - Gates',
        # 'C' => 'Airport - Terminal Waypoints',
        # 'D' => 'Airport - SIDs',
        # 'E' => 'Airport - STARs',
        # Approach Procedures
        'F' => 'RecordType:1
                CustomerAreaCode:3
                SectionCode:1
                BlankSpacing:1
                AirportIdentifier:4
                ICAOCode:2
                SubSectionCode:1
                SIDSTARApproachIdentifier:6
                RouteType:1
                TransitionIdentifier:5
                BlankSpacing:1
                SequenceNumber:3
                FixIdentifier:5
                ICAOCode:2
                SectionCode:1
                SubSectionCode:1
                ContinuationRecordNumber:1
                ApplicationType:1
                Remainder:92
                '
        ,

        # 'G' => 'Airport - Runways',
        # 'I' => 'Airport - Localizer/Glide Slope',
        # 'K' => 'Airport - TAA',
        # 'L' => 'Airport - MLS',
        # 'M' => 'Airport - Localizer Marker',
        # 'N' => 'Airport - Terminal NDB',
        'P' => 'RecordType:1
                CustomerAreaCode:3
                SectionCode:1
                Blank:1
                AirportIdentifier:4
                ICAOCode:2
                SubSectionCode:1
                ApproachProcedureIdent:6
                RunwayOrHelipadIdentifier:5
                OperationType:2
                ContinuationRecordNumber:1
                ApplicationType:1
                Remainder:104
                '
        ,

        # 'R' => 'Airport - Flt Planning ARR/DEP',
        # 'S' => 'Airport - MSA',
        # 'T' => 'Airport - GLS Station',
        # 'V' => 'Airport - Communications',
    },
    'R' => {

        # ''  => 'Company Routes - Company Routes',
        # 'A' => 'Company Routes - Alternate Records',

    },
    'T' => {

        # 'C' => 'Tables - Cruising Tables',
        # 'G' => 'Tables - Geographical Reference',
        # 'N' => 'Tables - RNAV Name Table',
    },
    'U' => {

        # 'C' => 'Airspace - Controlled Airspace',
        # 'F' => 'Airspace - FIR/UIR',
        'R' => 'RecordType:1
            CustomerAreaCode:3
            SectionCode:1
            SubsectionCode:1
            ICAOCode:2
            RestrictiveType:1
            RestrictiveAirspaceDesignation:10
            MultipleCode:1
            SequenceNumber:4
            ContinuationRecordNumber:1
            ApplicationType:1
            TimeCode:1
            NOTAM:1
            TimeIndicator:1
            TimeofOperations:10
            TimeofOperations:10
            TimeofOperations:10
            TimeofOperations:10
            TimeofOperations:10
            TimeofOperations:10
            TimeofOperations:10
            ControllingAgency:24
            FileRecordNumber:5
            CycleDate:4
            ',
    },
);

#Use these continuation parsers for SectionCode/SubsectionCodes that have application types
my %hash_of_continuation_application_parsers = (

    # 'A' => {

    # # 'S' => {}
    # },
    # 'D' => {

    # # '' => {
    # # '   ' => 'Navaid - VHF Navaid',
    # # },

    # # 'B' => {
    # # 'XX' => 'Navaid - NDB Navaid',
    # },
    # 'E' => {

    # # 'A' => 'Enroute - Grid Waypoints',
    # # 'M' => 'Enroute - Airway Markers',
    # # 'P' => 'Enroute - Holding Patterns',
    # # 'R' => 'Enroute - Airways and Routes',
    # # 'T' => 'Enroute - Preferred Routes',
    # # 'U' => 'Enroute - Airway Restrictions',
    # # 'V' => 'Enroute - Airway Restrictions',
    # },
    # 'H' => {

    # # 'A' => 'Heliport - Pads',
    # # 'C' => 'Heliport - Terminal Waypoints',
    # # 'D' => 'Heliport - SIDs',
    # # 'E' => 'Heliport - STARs',
    # # 'F' => 'Heliport - Approach Procedures',
    # # 'K' => 'Heliport - TAA',
    # # 'S' => 'Heliport - MSA',
    # # 'V' => 'Heliport - Communications',
    # },

    #Airport
    'P' => {

        # 'A' => 'Airport - Reference Points',
        # 'B' => 'Airport - Gates',
        # 'C' => 'Airport - Terminal Waypoints',
        # 'D' => 'Airport - SIDs',
        # 'E' => 'Airport - STARs',
        # Approach Procedures
        'F' => {

            # 'A' => 'ContinuationApplication',
            # 'B' => 'ContinuationApplication',
            # 'C' => 'ContinuationApplication',
            # 'E' => 'ContinuationApplication',
            # 'L' => 'ContinuationApplication',
            # 'N' => 'ContinuationApplication',
            # 'T' => 'ContinuationApplication',
            # 'U' => 'ContinuationApplication',
            # 'V' => 'ContinuationApplication',
            # 'P' => 'ContinuationApplication',
            # 'Q' => 'ContinuationApplication',
            # 'S' => 'ContinuationApplication',

            # An Airport or Heliport Procedure Data Continuation with SBAS use authorizationinformation
            'W' => 'RecordType:1
                CustomerAreaCode:3
                SectionCode:1
                BlankSpacing:1
                AirportIdentifier:4
                ICAOCode:2
                SubSectionCode:1
                SIDSTARApproachIdentifier:6
                RouteType:1
                TransitionIdentifier:5
                BlankSpacing:1
                SequenceNumber:3
                FixIdentifier:5
                ICAOCode:2
                SectionCode:1
                SubSectionCode:1
                ContinuationRecordNumber:1
                ApplicationType:1
                FASBlockProvided:1
                FASBlockProvidedLevelOfServiceName:10
                LNAVVNAVAuthorizedForSBAS:1
                LNAVVNAVLevelOfServiceName:10
                LNAVAuthorizedForSBAS:1
                LNAVLevelOfServiceName:10
                Blank_Spacing:45
                ApproachRouteTypeQualifier1:1
                ApproachRouteTypeQualifier2:1
                Blank:3
                FileRecordNumber:5
                CycleDate:4
                ',
        },

        # 'G' => 'Airport - Runways',
        # 'I' => 'Airport - Localizer/Glide Slope',
        # 'K' => 'Airport - TAA',
        # 'L' => 'Airport - MLS',
        # 'M' => 'Airport - Localizer Marker',
        # 'N' => 'Airport - Terminal NDB',
        'P' => {
            'E' => 'RecordType:1
            CustomerAreaCode:3
            SectionCode:1
            Blank:1
            AirportIdentifier:4
            ICAOCode:2
            SubSectionCode:1
            ApproachProcedureIdent:6
            RunwayOrHelipadIdentifier:5
            OperationType:2
            ContinuationRecordNumber:1
            ApplicationType:1
            FPAPEllipsoidHeight:6
            FPAPOrthometricHeight:6
            LTPOrthometricHeight:6
            ApproachTypeIdentifier:10
            GNSSChannelNumber:5
            BlankSpacing:10
            HelicopterProcedureCourse:3
            BlankSpacing:49
            FileRecordNumber:5
            CycleDate:4
            ',
        },

        # 'R' => 'Airport - Flt Planning ARR/DEP',
        # 'S' => 'Airport - MSA',
        # 'T' => 'Airport - GLS Station',
        # 'V' => 'Airport - Communications',
    },

    # 'R' => {

    # # ''  => 'Company Routes - Company Routes',
    # # 'A' => 'Company Routes - Alternate Records',

    # },
    # 'T' => {

    # # 'C' => 'Tables - Cruising Tables',
    # # 'G' => 'Tables - Geographical Reference',
    # # 'N' => 'Tables - RNAV Name Table',
    # },
    'U' => {

        # 'C' => 'Airspace - Controlled Airspace',
        # 'F' => 'Airspace - FIR/UIR',
        'R' => {
            'C' => 'RecordType:1
        CustomerAreaCode:3
        SectionCode:1
        SubsectionCode:1
        ICAOCode:2
        RestrictiveType:1
        RestrictiveAirspaceDesignation:10
        MultipleCode:1
        SequenceNumber:4
        ContinuationRecordNumber:1
        ApplicationType:1
        TimeCode:1
        NOTAM:1
        TimeIndicator:1
        TimeofOperations:10
        TimeofOperations:10
        TimeofOperations:10
        TimeofOperations:10
        TimeofOperations:10
        TimeofOperations:10
        TimeofOperations:10
        ControllingAgency:24
        FileRecordNumber:5
        CycleDate:4
        ',
        },
    },
);

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

#connect to the database
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

    # # warn "No record terminator found!\n" unless chomp;
    # warn "Short Record!\n" unless $parser_base->length == length ($textOfCurrentLine);

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
