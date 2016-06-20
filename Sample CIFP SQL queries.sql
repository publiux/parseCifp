-- If you feel like outputting query results to CSV:
-- sqlite3 cifp-1513.db
-- .headers on
-- .mode csv
-- .output filename.csv
--------------------------------------------------------------------------------
--Controlled airspace points
-- Needs some calculations on this data to produce GML compatible output
.headers on
.mode csv
.output controlled-airspace.csv
SELECT 
    AirspaceCenter
    , AirspaceClassification
    , AirspaceType
    , BoundaryVia_1
    , BoundaryVia_2
    , ( CAST( ArcBearing AS REAL) / 10) as ArcBearing
    , ( CAST( ArcDistance AS REAL) / 10) as ArcDistance 
    , ArcOriginLongitude_WGS84
    , ArcOriginLatitude_WGS84
    , ControlledAirspaceName
    , Longitude_WGS84
    , Latitude_WGS84
    , LowerLimit
    , UpperLimit

FROM
    "primary_U_C_base_Airspace - Controlled Airspace" 
        AS airspace

-- WHERE
--     airspace.AirspaceCenter LIKE  '%SSC%'
    ;
--------------------------------------------------------------------------------
-- Restrictive airspace points
-- Needs some calculations on this data to produce GML compatible output
.headers on
.mode csv
.output restrictive-airspace.csv
SELECT 
    RestrictiveAirspaceDesignation
    , RestrictiveAirspaceName
    , RestrictiveType
    , NOTAM
    , BoundaryVia_1
    , BoundaryVia_2
    , ( CAST( ArcBearing AS REAL) / 10) as ArcBearing
    , ( CAST( ArcDistance AS REAL) / 10) as ArcDistance 
    , ArcOriginLongitude_WGS84
    , ArcOriginLatitude_WGS84     
    , Longitude_WGS84
    , Latitude_WGS84    
    , LowerLimit
    , UpperLimit


FROM
    "primary_U_R_base_Airspace - Restrictive Airspace"
        AS airspace

-- WHERE
--     airspace.AirspaceCenter LIKE  '%SSC%'
    ;
--------------------------------------------------------------------------------
--IAPs (all steps) at an airport
SELECT *
    --iap.LandingFacilityIcaoIdentifier
    --,iap.SIDSTARApproachIdentifier

FROM
    "primary_P_F_base_Airport - Approach Procedures" AS IAP

WHERE
    iap.LandingFacilityIcaoIdentifier LIKE  '%RIC%'
--         and
--     iap.SIDSTARApproachIdentifier LIKE  '%18%'
    ;
--------------------------------------------------------------------------------
--IAPs (all steps) at an airport, with the more interesting parts of each step
SELECT
    iap._id
    ,LandingFacilityIcaoIdentifier
    ,SIDSTARApproachIdentifier
    ,TransitionIdentifier
    ,CAST( SequenceNumber AS REAL)
    ,RouteType
    ,FixIdentifier
    ,WaypointDescriptionCode1
    ,WaypointDescriptionCode2
    ,WaypointDescriptionCode3
    ,WaypointDescriptionCode4
    ,PathAndTermination
    ,CAST( MagneticCourse AS REAL) / 10
    ,CAST( Altitude_1 AS REAL)
    ,CAST( Altitude_2 AS REAL)
    ,AltitudeDescription
    ,CAST( Rho AS REAL) / 10
    ,RecommendedNavaid
    ,RNP
    ,CAST( RouteDistanceHoldingDistanceOrTime AS REAL) / 10
    ,VerticalAngle
    ,CAST (Theta AS REAL) / 10
    ,CAST( TransitionAltitude AS REAL)
    ,TurnDirection
    ,TurnDirectionValid
    ,SpeedLimit
    ,SpeedLimitDescription

FROM
    "primary_P_F_base_Airport - Approach Procedures" AS iap
WHERE
    iap.LandingFacilityIcaoIdentifier LIKE  '%RIC%'
ORDER BY
    SIDSTARApproachIdentifier
    ,RouteType
    ,TransitionIdentifier
    ,CAST( SequenceNumber AS REAL)
    ;
--------------------------------------------------------------------------------
---Minimum Safe Altitudes at an airport, all info
SELECT
    *
FROM
    "primary_P_S_base_Airport - MSA" AS msa
WHERE
    --msa.LandingFacilityIcaoIdentifier LIKE  '%RIC%'
    msa.LandingFacilityIcaoIdentifier IN ('KART')
    ;
--------------------------------------------------------------------------------
-- Or just the more interesting parts of MSA
.headers on
.mode csv
.output MSA_points.csv

SELECT
    msa.LandingFacilityIcaoIdentifier
    ,msa.MagneticTrueIndicator
    ,msa.MSACenter
    ,msa.LandingFacilityIcaoRegionCode
    ,msa.MSACenterIcaoRegionCode
    ,msa.SectionCode
    ,msa.SubSectionCode
    ,msa.MSACenterSectionCode
    ,msa.MSACenterSubSectionCode
    ,SectorAltitude_1
    ,SectorBearing_1
    ,SectorRadius_1
    ,SectorAltitude_2
    ,SectorBearing_2
    ,SectorRadius_2
    ,SectorAltitude_3
    ,SectorBearing_3
    ,SectorRadius_3
    ,SectorAltitude_4
    ,SectorBearing_4
    ,SectorRadius_4
    ,SectorAltitude_5
    ,SectorBearing_5
    ,SectorRadius_5
    ,SectorAltitude_6
    ,SectorBearing_6
    ,SectorRadius_6
    ,SectorAltitude_7
    ,SectorBearing_7
    ,SectorRadius_7
    , COALESCE( term_fix.waypointLongitude_wgs84
                ,vhf.vorLongitude_wgs84
                ,ndb.ndbLongitude_wgs84
                ,term_ndb.ndbLongitude_wgs84
                ,grid.waypointLongitude_wgs84
                ,vhf.dmeLongitude_wgs84
                ,rwy.RunwayLongitude_wgs84
                )
                    AS Longitude
    , COALESCE( term_fix.waypointLatitude_wgs84
                ,vhf.vorLatitude_wgs84
                ,ndb.ndbLatitude_wgs84
                ,term_ndb.ndbLatitude_wgs84
                ,grid.waypointLatitude_wgs84
                ,vhf.dmeLatitude_wgs84
                ,rwy.RunwayLatitude_wgs84
                )
                    AS Latitude
    , 'point ('
        || COALESCE(    term_fix.waypointLongitude_wgs84
                        ,vhf.vorLongitude_wgs84
                        ,ndb.ndbLongitude_wgs84
                        ,term_ndb.ndbLongitude_wgs84
                        ,grid.waypointLongitude_wgs84
                        ,vhf.dmeLongitude_wgs84
                        ,rwy.RunwayLongitude_wgs84
                        )
        || ' '
        || COALESCE(    term_fix.waypointLatitude_wgs84
                        ,vhf.vorLatitude_wgs84
                        ,ndb.ndbLatitude_wgs84
                        ,term_ndb.ndbLatitude_wgs84
                        ,grid.waypointLatitude_wgs84
                        ,vhf.dmeLatitude_wgs84
                        ,rwy.RunwayLatitude_wgs84
                        ) 
        || ' )'
            as Geometry

FROM
    "primary_P_S_base_Airport - MSA" AS msa
    
LEFT OUTER JOIN
    "primary_E_A_base_Enroute - Grid Waypoints" AS grid
        ON
            (msa.MSACenterSectionCode = 'E' AND msa.MSACenterSubSectionCode = 'A')
                AND
            msa.MSACenter = grid.waypointIdentifier
                AND
            msa.MSACenterIcaoRegionCode = grid.WaypointIcaoRegionCode
            
LEFT OUTER JOIN
    "primary_P_C_base_Airport - Terminal Waypoints" AS term_fix
        ON
            (msa.MSACenterSectionCode = 'P' AND msa.MSACenterSubSectionCode = 'C')
                AND
            msa.LandingFacilityIcaoIdentifier = term_fix.RegionCode
                AND
            msa.MSACenter = term_fix.waypointIdentifier
                AND 
            msa.MSACenterIcaoRegionCode = term_fix.WaypointIcaoRegionCode

LEFT OUTER JOIN
    "primary_D__base_Navaid - VHF Navaid" AS vhf
        ON
            (msa.MSACenterSectionCode = 'D' AND msa.MSACenterSubSectionCode = '')
                AND
            msa.MSACenterIcaoRegionCode = vhf.VorIcaoRegionCode
                AND
            msa.MSACenter = vhf.vorIdentifier

LEFT OUTER JOIN
    "primary_D_B_base_Navaid - NDB Navaid" AS ndb
        ON
            (msa.MSACenterSectionCode = 'D' AND msa.MSACenterSubSectionCode = 'B')
                AND
            msa.MSACenterIcaoRegionCode = ndb.NdbIcaoRegionCode
                AND
            msa.MSACenter = ndb.ndbIdentifier

LEFT OUTER JOIN
    "primary_P_N_base_Airport - Terminal NDB" AS term_ndb
        ON
            (msa.MSACenterSectionCode = 'P' AND msa.MSACenterSubSectionCode = 'N')
                AND
            msa.MSACenterIcaoRegionCode = term_ndb.NdbIcaoRegionCode
                AND
            msa.MSACenter = term_ndb.ndbIdentifier
                AND
            msa.LandingFacilityIcaoIdentifier = term_ndb.LandingFacilityIcaoIdentifier

LEFT OUTER JOIN
    "primary_P_G_base_Airport - Runways" AS rwy
        ON
           (msa.MSACenterSectionCode = 'P' AND msa.MSACenterSubSectionCode = 'G')
                AND
            msa.MSACenter = rwy.runwayIdentifier
                AND
            msa.LandingFacilityIcaoIdentifier = rwy.LandingFacilityIcaoIdentifier

-- WHERE
--     msa.LandingFacilityIcaoIdentifier LIKE  '%RIC%'
--     msa.LandingFacilityIcaoIdentifier IN ('KART')
    ;
--------------------------------------------------------------------------------
--SIDs at an airport
SELECT distinct
    sids.LandingFacilityIcaoIdentifier
    ,sids.SIDSTARApproachIdentifier
FROM
    "primary_P_D_base_Airport - SIDs" AS sids

WHERE
    sids.LandingFacilityIcaoIdentifier = 'KRIC'
    ;
--------------------------------------------------------------------------------
--STARs at an airport
SELECT DISTINCT
    stars.LandingFacilityIcaoIdentifier
    ,stars.SIDSTARApproachIdentifier
FROM
    "primary_P_E_base_Airport - STARs" AS stars
WHERE
    stars.LandingFacilityIcaoIdentifier =  'KRIC'
    ;
--------------------------------------------------------------------------------
--IAPs at an airport
SELECT DISTINCT
    iap.LandingFacilityIcaoIdentifier
    ,iap.SIDSTARApproachIdentifier

FROM
    "primary_P_F_base_Airport - Approach Procedures" AS IAP

WHERE
    iap.LandingFacilityIcaoIdentifier =  'KRIC'
    ;

--------------------------------------------------------------------------------
--Runways at an airport
SELECT DISTINCT
    rwy.LandingFacilityIcaoIdentifier
    ,rwy.RunwayIdentifier
    ,rwy.RunwayLatitude
    ,rwy.RunwayLongitude
    ,rwy.RunwayLatitude_wgs84
    ,rwy.RunwayLongitude_wgs84
FROM
    "primary_P_G_base_Airport - Runways" AS RWY

WHERE
    rwy.LandingFacilityIcaoIdentifier =  'KRIC' ;
--------------------------------------------------------------------------------
--Longest runway's length at an airport (rwy.LongestRunway is hundreds of feet.  eg 090 = 9000')
SELECT 
    rwy.LandingFacilityIcaoIdentifier
    , rwy.LongestRunway
    , CAST(rwy.LongestRunway AS REAL) * 100 AS runwayLengthInFeet

FROM
    "primary_P_A_base_Airport - Reference Points" AS RWY

WHERE
    rwy.LandingFacilityIcaoIdentifier IN ('KRIC', 'KDCA', 'KIAD', 'KORF') ;
--------------------------------------------------------------------------------
--NDB Navaids used for IAPs for an airport
-- Needs to be fixed to correctly use joining criteria (see MSA for example
SELECT DISTINCT
    iap.FixIdentifier
    ,NDB.NDBLatitude
    ,NDB.NDBLongitude
FROM
    "primary_P_F_base_Airport - Approach Procedures" AS IAP

JOIN
    "primary_D_B_base_Navaid - NDB Navaid" AS NDB

ON
    iap.FixIdentifier = ndb.NDBIdentifier

WHERE
    airportidentifier LIKE  '%RIC%' ;
--------------------------------------------------------------------------------
-- Needs to be fixed to correctly use joining criteria (see MSA for example)
--VHF Navaids used for IAPs for an airport
SELECT DISTINCT
    iap.FixIdentifier
    ,VOR.VORLatitude
    ,VOR.VORLongitude
FROM
    "primary_P_F_base_Airport - Approach Procedures" AS IAP

JOIN
    "primary_D__base_Navaid - VHF Navaid" AS VOR

ON
    iap.FixIdentifier = vor.vorIdentifier

WHERE
    airportidentifier LIKE  '%RIC%' ;
--------------------------------------------------------------------------------
-- Needs to be fixed to correctly use joining criteria (see MSA for example)
--Fixes used for IAPs for an airport
SELECT DISTINCT
    iap.FixIdentifier
    ,fix.waypointLatitude
    ,fix.waypointLongitude
FROM
    "primary_P_F_base_Airport - Approach Procedures" AS IAP

JOIN
    "primary_E_A_base_Enroute - Grid Waypoints" AS FIX

ON
    iap.FixIdentifier = fix.waypointIdentifier

WHERE
    airportidentifier LIKE  '%RIC%'
    ;
--------------------------------------------------------------------------------
-- Needs to be fixed to correctly use joining criteria (see MSA for example)
--Terminal waypoints used for IAPs for an airport
SELECT DISTINCT
    iap.FixIdentifier
    ,fix.waypointLatitude
    ,fix.waypointLongitude
FROM
    "primary_P_F_base_Airport - Approach Procedures" AS IAP
JOIN
    "primary_P_C_base_Airport - Terminal Waypoints" AS FIX

ON
    iap.FixIdentifier = fix.waypointIdentifier

WHERE
    airportidentifier LIKE  '%OFP%' ;


--------------------------------------------------------------------------------
-- Needs to be fixed to correctly use joining criteria (see MSA for example)
--Terminal waypoints used for IAPs for a heliport
SELECT DISTINCT
    iap.FixIdentifier
    ,fix.waypointLatitude
    ,fix.waypointLongitude
FROM
    "primary_H_F_base_Heliport - Approach Procedures" AS IAP

JOIN
    "primary_E_A_base_Enroute - Grid Waypoints" AS FIX

ON
    iap.FixIdentifier = fix.waypointIdentifier

WHERE
    HeliportIdentifier LIKE  '%RIC%' ;
--------------------------------------------------------------------------------
SELECT
    --_id
    --,LandingFacilityIcaoIdentifier
    --,Altitude_1
    --,Altitude_2
    --,AltitudeDescription
    --,ApchRouteQualifier1
    --,ApchRouteQualifier2
    --,ARCRadius
    --,ATCIndicator
    --,CenterFixOrTAAProcedureTurnIndicator
    --,FileRecordNumber
    FixIdentifier
    --,MagneticCourse
    --,MultipleCodeOrTAASectorIdentifier
    --,PathAndTermination
    --,RNP
    --,RouteDistanceHoldingDistanceOrTime
    --,RouteType
    --,SequenceNumber
    --,SIDSTARApproachIdentifier
    --,SpeedLimit
    --,SpeedLimitDescription
    --,SubSectionCode_1
    --,SubSectionCode_2
    --,SubSectionCode_3
    --,Theta
    --,TransitionAltitude
    --,TransitionIdentifier
    --,TurnDirection
    --,TurnDirectionValid
    --,VerticalAngle
    --,WaypointDescriptionCode1
    --,WaypointDescriptionCode2
    --,WaypointDescriptionCode3
    --,WaypointDescriptionCode4

FROM
    --"primary_P_F_base_Airport - Approach Procedures "
    "primary_H_F_base_Heliport - Approach Procedures"
WHERE
    --airportidentifier LIKE  '%02p%'
    heliportidentifier LIKE  '%02p%'
ORDER BY
    SidstarApproachIdentifier
    ,TransitionIdentifier
    ,SequenceNumber
    ;
--------------------------------------------------------------------------------
SELECT
    *
FROM
    "primary_H_F_base_Heliport - Approach Procedures"
WHERE
    heliportidentifier LIKE  '%02P%'
    ;

------------------------------------------------------------------------------
--Create lines for all procedures.  Doesn't look quite right due to the fact 
-- that these types of legs in the procedure don't have specific associated fixes
-- "CA" -Course to an Altitude or CA Leg. 
--      Defines a specified course to a specific altitude at an unspecified position"
-- "CD" - Course to a DME Distance or CD Leg. 
--      Defines a specified course to a specific DME Distance which is from a 
--      specific database DME Navaid.
-- "CI" - Course to an Intercept or CI Leg. 
--      Defines a specified course to intercept a subsequent leg.
-- "VA" - Heading to an Altitude termination or VA Leg. 
--      Defines a specified heading to a specific Altitude termination at an 
--      unspecified position.
-- "VD" - Heading to a DME Distance termination or VD Leg. 
--      Defines a specified heading terminating at a specified DME Distance 
--      from a specific database DME Navaid.
-- "VI" - Heading to an Intercept or VI Leg. 
--      Defines a specified heading to intercept the subsequent leg at an 
--      unspecified position.
-- "VR" - Heading to a Radial termination or VR Leg. 
--      Defines a specified heading to a specified radial from a specific 
--      database VOR Navaid.

.headers on
.mode csv
.output "iap-lines.csv"
-- .output "sid-lines.csv"
-- .output "star-lines.csv"

SELECT
    procedure._id
    , procedure.LandingFacilityIcaoIdentifier
    , procedure.SIDSTARApproachIdentifier
    , procedure.TransitionIdentifier
    , procedure.LandingFacilityIcaoIdentifier 
        || '.' 
        || procedure.SIDSTARApproachIdentifier 
        || '.' 
        || procedure.TransitionIdentifier 
            as unique_id
    , procedure.RouteType
    , COALESCE( term_fix.waypointLongitude_wgs84
                ,vhf.vorLongitude_wgs84
                ,ndb.ndbLongitude_wgs84
                ,term_ndb.ndbLongitude_wgs84
                ,grid.waypointLongitude_wgs84
                ,vhf.dmeLongitude_wgs84
                ,rwy.RunwayLongitude_wgs84
                )
                    AS Longitude
    , COALESCE( term_fix.waypointLatitude_wgs84
                ,vhf.vorLatitude_wgs84
                ,ndb.ndbLatitude_wgs84
                ,term_ndb.ndbLatitude_wgs84
                ,grid.waypointLatitude_wgs84
                ,vhf.dmeLatitude_wgs84
                ,rwy.RunwayLatitude_wgs84
                )
                    AS Latitude
    , 'linestring ('
        || GROUP_CONCAT(
                COALESCE(   term_fix.waypointLongitude_wgs84
                        ,vhf.vorLongitude_wgs84
                        ,ndb.ndbLongitude_wgs84
                        ,term_ndb.ndbLongitude_wgs84
                        ,grid.waypointLongitude_wgs84
                        ,vhf.dmeLongitude_wgs84
                        ,rwy.RunwayLongitude_wgs84
                        )
            || ' '
            || COALESCE(   term_fix.waypointLatitude_wgs84
                        ,vhf.vorLatitude_wgs84
                        ,ndb.ndbLatitude_wgs84
                        ,term_ndb.ndbLatitude_wgs84
                        ,grid.waypointLatitude_wgs84
                        ,vhf.dmeLatitude_wgs84
                        ,rwy.RunwayLatitude_wgs84
                        ) 
            || ' )'
            )
        AS
            geometry

FROM
    "primary_P_F_base_Airport - Approach Procedures" AS procedure
    --, 'primary_P_E_base_Airport - STARs' AS procedure
    --, 'primary_P_D_base_Airport - SIDs' AS procedure


LEFT OUTER JOIN
    "primary_E_A_base_Enroute - Grid Waypoints" AS grid
        ON
            (procedure.FixSectionCode = 'E' AND procedure.FixSubSectionCode = 'A')
                AND
            procedure.FixIdentifier = grid.waypointIdentifier
                AND
            procedure.FixIcaoRegionCode = grid.WaypointIcaoRegionCode
            
LEFT OUTER JOIN
    "primary_P_C_base_Airport - Terminal Waypoints" AS term_fix
        ON
            (procedure.FixSectionCode = 'P' AND procedure.FixSubSectionCode = 'C')
                AND
            procedure.LandingFacilityIcaoIdentifier = term_fix.RegionCode
                AND
            procedure.FixIdentifier = term_fix.waypointIdentifier
                AND 
            procedure.FixIcaoRegionCode = term_fix.WaypointIcaoRegionCode

LEFT OUTER JOIN
    "primary_D__base_Navaid - VHF Navaid" AS vhf
        ON
            (procedure.FixSectionCode = 'D' AND procedure.FixSubSectionCode = '')
                AND
            procedure.FixIcaoRegionCode = vhf.VorIcaoRegionCode
                AND
            procedure.FixIdentifier = vhf.vorIdentifier

LEFT OUTER JOIN
    "primary_D_B_base_Navaid - NDB Navaid" AS ndb
        ON
            (procedure.FixSectionCode = 'D' AND procedure.FixSubSectionCode = 'B')
                AND
            procedure.FixIcaoRegionCode = ndb.NdbIcaoRegionCode
                AND
            procedure.FixIdentifier = ndb.ndbIdentifier

LEFT OUTER JOIN
    "primary_P_N_base_Airport - Terminal NDB" AS term_ndb
        ON
            (procedure.FixSectionCode = 'P' AND procedure.FixSubSectionCode = 'N')
                AND
            procedure.FixIcaoRegionCode = term_ndb.NdbIcaoRegionCode
                AND
            procedure.FixIdentifier = term_ndb.ndbIdentifier
                AND
            procedure.LandingFacilityIcaoIdentifier = term_ndb.LandingFacilityIcaoIdentifier            

LEFT OUTER JOIN
    "primary_P_G_base_Airport - Runways" AS rwy
        ON
           (procedure.FixSectionCode = 'P' AND procedure.FixSubSectionCode = 'G')
                AND
            procedure.FixIdentifier = rwy.runwayIdentifier
                AND
            procedure.LandingFacilityIcaoIdentifier = rwy.LandingFacilityIcaoIdentifier
            
WHERE
--     procedure.LandingFacilityIcaoIdentifier LIKE '%CAE%'
--            AND
    procedure.FixIdentifier IS NOT NULL
        AND 
    (Longitude IS NOT NULL AND Longitude != '')
        AND 
    (Latitude IS NOT NULL AND Latitude != '')

GROUP BY
    unique_id
ORDER BY
    CAST(procedure.SequenceNumber AS real)
;

------------------------------------------------------------------------------
-- Points associated with procedures

.headers on
.mode csv
.output "iap-points.csv"
-- .output "sid-points.csv"
-- .output "star-points.csv"

SELECT
    procedure._id
    , procedure.LandingFacilityIcaoIdentifier
    , procedure.SIDSTARApproachIdentifier
    , procedure.TransitionIdentifier
    , procedure.LandingFacilityIcaoIdentifier 
        || '.' 
        || procedure.SIDSTARApproachIdentifier 
        || '.' 
        || procedure.TransitionIdentifier 
            as unique_id
    , procedure.FixIdentifier
    , procedure.SequenceNumber
    , procedure.RouteType
    , procedure.WaypointDescriptionCode1
    , procedure.WaypointDescriptionCode2
    , procedure.WaypointDescriptionCode3
    , procedure.WaypointDescriptionCode4
    , procedure.PathAndTermination
    , procedure.MagneticCourse
    , procedure.Altitude_1
    , procedure.Altitude_2
    , procedure.AltitudeDescription
    , procedure.Rho
    , procedure.RNP
    , procedure.RouteDistanceHoldingDistanceOrTime
    , procedure.VerticalAngle
    , procedure.Theta
    , procedure.TransitionAltitude
    , procedure.TurnDirection
    , procedure.TurnDirectionValid
    , COALESCE( term_fix.waypointLongitude_wgs84
                ,vhf.vorLongitude_wgs84
                ,ndb.ndbLongitude_wgs84
                ,term_ndb.ndbLongitude_wgs84
                ,grid.waypointLongitude_wgs84
                ,vhf.dmeLongitude_wgs84
                ,rwy.RunwayLongitude_wgs84
                )
                    AS Longitude
    , COALESCE( term_fix.waypointLatitude_wgs84
                ,vhf.vorLatitude_wgs84
                ,ndb.ndbLatitude_wgs84
                ,term_ndb.ndbLatitude_wgs84
                ,grid.waypointLatitude_wgs84
                ,vhf.dmeLatitude_wgs84
                ,rwy.RunwayLatitude_wgs84
                )
                    AS Latitude
    , 'point( ' 
        || COALESCE(    term_fix.waypointLongitude_wgs84
                ,vhf.vorLongitude_wgs84
                ,ndb.ndbLongitude_wgs84
                ,term_ndb.ndbLongitude_wgs84
                ,grid.waypointLongitude_wgs84
                ,vhf.dmeLongitude_wgs84
                ,rwy.RunwayLongitude_wgs84
                )
        || ' '
        || COALESCE(    term_fix.waypointLatitude_wgs84
                ,vhf.vorLatitude_wgs84
                ,ndb.ndbLatitude_wgs84
                ,term_ndb.ndbLatitude_wgs84
                ,grid.waypointLatitude_wgs84
                ,vhf.dmeLatitude_wgs84
                ,rwy.RunwayLatitude_wgs84
                ) 
        || ' )' 
            AS geometry

FROM
    "primary_P_F_base_Airport - Approach Procedures" AS procedure
    --, 'primary_P_E_base_Airport - STARs' AS procedure
    --, 'primary_P_D_base_Airport - SIDs' AS procedure

LEFT OUTER JOIN
    "primary_E_A_base_Enroute - Grid Waypoints" AS grid
        ON
            (procedure.FixSectionCode = 'E' AND procedure.FixSubSectionCode = 'A')
                AND
            procedure.FixIdentifier = grid.waypointIdentifier
                AND
            procedure.FixIcaoRegionCode = grid.WaypointIcaoRegionCode
            
LEFT OUTER JOIN
    "primary_P_C_base_Airport - Terminal Waypoints" AS term_fix
        ON
            (procedure.FixSectionCode = 'P' AND procedure.FixSubSectionCode = 'C')
                AND
            procedure.LandingFacilityIcaoIdentifier = term_fix.RegionCode
                AND
            procedure.FixIdentifier = term_fix.waypointIdentifier
                AND 
            procedure.FixIcaoRegionCode = term_fix.WaypointIcaoRegionCode

LEFT OUTER JOIN
    "primary_D__base_Navaid - VHF Navaid" AS vhf
        ON
            (procedure.FixSectionCode = 'D' AND procedure.FixSubSectionCode = '')
                AND
            procedure.FixIcaoRegionCode = vhf.VorIcaoRegionCode
                AND
            procedure.FixIdentifier = vhf.vorIdentifier

LEFT OUTER JOIN
    "primary_D_B_base_Navaid - NDB Navaid" AS ndb
        ON
            (procedure.FixSectionCode = 'D' AND procedure.FixSubSectionCode = 'B')
                AND
            procedure.FixIcaoRegionCode = ndb.NdbIcaoRegionCode
                AND
            procedure.FixIdentifier = ndb.ndbIdentifier

LEFT OUTER JOIN
    "primary_P_N_base_Airport - Terminal NDB" AS term_ndb
        ON
            (procedure.FixSectionCode = 'P' AND procedure.FixSubSectionCode = 'N')
                AND
            procedure.FixIcaoRegionCode = term_ndb.NdbIcaoRegionCode
                AND
            procedure.FixIdentifier = term_ndb.ndbIdentifier
                AND
            procedure.LandingFacilityIcaoIdentifier = term_ndb.LandingFacilityIcaoIdentifier            

LEFT OUTER JOIN
    "primary_P_G_base_Airport - Runways" AS rwy
        ON
           (procedure.FixSectionCode = 'P' AND procedure.FixSubSectionCode = 'G')
                AND
            procedure.FixIdentifier = rwy.runwayIdentifier
                AND
            procedure.LandingFacilityIcaoIdentifier = rwy.LandingFacilityIcaoIdentifier

WHERE
--     procedure.LandingFacilityIcaoIdentifier LIKE '%NUQ%'
--         AND
    procedure.FixIdentifier IS NOT NULL
        AND 
    (Longitude IS NOT NULL AND Longitude != '')
        AND 
   (Latitude IS NOT NULL AND Latitude != '')

-- GROUP BY
--     unique_id
-- ORDER BY
--     CAST(procedure.SequenceNumber AS real)
;

--------------------------------------------------------------------------------
-- The set of distinct route types and qualifiers
--  and their more verbose descriptions
SELECT DISTINCT
    procedure.RouteType
    ||  CASE
            WHEN procedure.ApchRouteQualifier1 = '' THEN '_'
            ELSE procedure.ApchRouteQualifier1
        END
    ||  CASE
            WHEN procedure.ApchRouteQualifier2 = '' THEN '_'
            ELSE procedure.ApchRouteQualifier2
        END
        AS Qualifiers
    , route_type.Route_Type_Description
    , route_qualifier.Qualifier_1_Description
    , route_qualifier2.Qualifier_2_Description
    , count(*) as CountOfSteps
FROM
    "primary_P_F_base_Airport - Approach Procedures" AS procedure
LEFT OUTER JOIN
    "route_types" AS route_type
        on
        procedure.SectionCode = route_type.Section
            and
        procedure.SubSectionCode = route_type.SubSection
         and
        procedure.RouteType = route_type.type_code
    
LEFT OUTER JOIN
    "route_qualifiers" AS route_qualifier
         on
       procedure.SectionCode = route_qualifier.Section
        and
       procedure.SubSectionCode = route_qualifier.SubSection
        and
       procedure.ApchRouteQualifier1 = route_qualifier.qualifier_1
LEFT OUTER JOIN
    "route_qualifiers" AS route_qualifier2
         on
       procedure.SectionCode = route_qualifier2.Section
        and
       procedure.SubSectionCode = route_qualifier2.SubSection
        and
         procedure.ApchRouteQualifier2 = route_qualifier2.qualifier_2    
group by
    Qualifiers
order by
    Qualifiers
    --, CountOfSteps ASC
;
--------------------------------------------------------------------------------