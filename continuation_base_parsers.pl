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
      }
