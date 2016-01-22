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
    --iap.AirportIdentifier
    --,iap.SIDSTARApproachIdentifier

FROM
    "primary_P_F_base_Airport - Approach Procedures" AS IAP

WHERE
    iap.AirportIdentifier LIKE  '%RIC%'
--         and
--     iap.SIDSTARApproachIdentifier LIKE  '%18%'
    ;
--------------------------------------------------------------------------------
--IAPs (all steps) at an airport, with the interesting parts of each step
SELECT
    iap._id
    ,AirportIdentifier
    ,SIDSTARApproachIdentifier
    ,TransitionIdentifier
    ,SequenceNumber
    ,RouteType
    ,FixIdentifier
    ,WaypointDescriptionCode1
    ,WaypointDescriptionCode2
    ,WaypointDescriptionCode3
    ,WaypointDescriptionCode4
    ,PathAndTermination
    ,MagneticCourse
    ,Altitude_1
    ,Altitude_2
    ,AltitudeDescription
    ,Rho
    ,RecommendedNavaid
    ,RNP
    ,RouteDistanceHoldingDistanceOrTime
    ,VerticalAngle
    ,Theta
    ,TransitionAltitude
    ,TurnDirection
    ,TurnDirectionValid
    ,SpeedLimit
    ,SpeedLimitDescription
    ,terminal.WaypointLatitude_WGS84
    ,terminal.WaypointLongitude_WGS84

FROM
    "primary_P_F_base_Airport - Approach Procedures" AS iap
JOIN
    "primary_P_C_base_Airport - Terminal Waypoints" AS terminal
--     "primary_E_A_base_Enroute - Grid Waypoints" AS enroute
ON
    iap.FixIdentifier = terminal.waypointIdentifier
--         or
--     iap.FixIdentifier = enroute.waypointIdentifier
    
WHERE
    iap.AirportIdentifier LIKE  '%ART%'
ORDER BY
    iap._id
    ;
--------------------------------------------------------------------------------
---Minimum Safe Altitudes at an airport, all info
SELECT
    *
FROM
    "primary_P_S_base_Airport - MSA" AS msa
WHERE
    --msa.AirportIdentifier LIKE  '%RIC%'
    msa.AirportIdentifier IN ('KART')
    ;
--------------------------------------------------------------------------------
-- Or just the more interesting parts of MSA
.headers on
.mode csv
.output MSA_points.csv

SELECT
    AirportIdentifier
    ,MagneticTrueIndicator
    ,MSACenter
    ,msa.IcaoCode_1
    ,msa.IcaoCode_2
    ,msa.SectionCode_1
    ,msa.SubSectionCode_1
    ,msa.SectionCode_2
    ,msa.SubSectionCode_2
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
            (msa.SectionCode_2 = 'E' AND msa.SubSectionCode_2 = 'A')
                AND
            msa.MSACenter = grid.waypointIdentifier
                AND
            msa.IcaoCode_2 = grid.IcaoCode_2
            
LEFT OUTER JOIN
    "primary_P_C_base_Airport - Terminal Waypoints" AS term_fix
        ON
            (msa.SectionCode_2 = 'P' AND msa.SubSectionCode_2 = 'C')
                AND
            msa.AirportIdentifier = term_fix.RegionCode
                AND
            msa.MSACenter = term_fix.waypointIdentifier
                AND 
            msa.IcaoCode_2 = term_fix.IcaoCode_2

LEFT OUTER JOIN
    "primary_D__base_Navaid - VHF Navaid" AS vhf
        ON
            (msa.SectionCode_2 = 'D' AND msa.SubSectionCode_2 = '')
                AND
            msa.IcaoCode_2 = vhf.IcaoCode_2
                AND
            msa.MSACenter = vhf.vorIdentifier

LEFT OUTER JOIN
    "primary_D_B_base_Navaid - NDB Navaid" AS ndb
        ON
            (msa.SectionCode_2 = 'D' AND msa.SubSectionCode_2 = 'B')
                AND
            msa.IcaoCode_2 = ndb.IcaoCode_2
                AND
            msa.MSACenter = ndb.ndbIdentifier

LEFT OUTER JOIN
    "primary_P_N_base_Airport - Terminal NDB" AS term_ndb
        ON
            (msa.SectionCode_2 = 'P' AND msa.SubSectionCode_2 = 'N')
                AND
            msa.IcaoCode_2 = term_ndb.IcaoCode_2
                AND
            msa.MSACenter = term_ndb.ndbIdentifier
                AND
            msa.AirportIdentifier = term_ndb.AirportIcaoIdentifier

LEFT OUTER JOIN
    "primary_P_G_base_Airport - Runways" AS rwy
        ON
           (msa.SectionCode_2 = 'P' AND msa.SubSectionCode_2 = 'G')
                AND
            msa.MSACenter = rwy.runwayIdentifier
                AND
            msa.AirportIdentifier = rwy.AirportIcaoIdentifier

-- WHERE
--     msa.AirportIdentifier LIKE  '%RIC%'
--     msa.AirportIdentifier IN ('KART')
    ;
--------------------------------------------------------------------------------
--SIDs at an airport
SELECT distinct
    sids.AirportIdentifier
    ,sids.SIDSTARApproachIdentifier

FROM
    "primary_P_D_base_Airport - SIDs" AS sids

WHERE
    sids.AirportIdentifier = 'KRIC'
    ;
--------------------------------------------------------------------------------
--STARs at an airport
SELECT DISTINCT
    stars.AirportIdentifier
    ,stars.SIDSTARApproachIdentifier

FROM
    "primary_P_E_base_Airport - STARs" AS stars

WHERE
    stars.AirportIdentifier LIKE  '%RIC%'
    ;
--------------------------------------------------------------------------------
--IAPs at an airport
SELECT DISTINCT
    iap.AirportIdentifier
    ,iap.SIDSTARApproachIdentifier

FROM
    "primary_P_F_base_Airport - Approach Procedures" AS IAP

WHERE
    iap.AirportIdentifier LIKE  '%RIC%'
    ;

--------------------------------------------------------------------------------
--Runways at an airport
SELECT DISTINCT
    rwy.AirportICAOIdentifier
    ,rwy.RunwayIdentifier
    ,rwy.RunwayLatitude
    ,rwy.RunwayLongitude
    ,rwy.RunwayLatitude_wgs84
    ,rwy.RunwayLongitude_wgs84
FROM
    "primary_P_G_base_Airport - Runways" AS RWY

WHERE
    rwy.AirportICAOIdentifier LIKE  '%RIC%' ;
--------------------------------------------------------------------------------
--Longest runway's length at an airport (in hundreds of feet.  eg 090 = 9000')
SELECT DISTINCT
    rwy.AirportICAOIdentifier
    ,rwy.LongestRunway

FROM
    "primary_P_A_base_Airport - Reference Points" AS RWY

WHERE
    rwy.AirportICAOIdentifier in ('KRIC', 'KDCA', 'KIAD', 'KORF') ;
--------------------------------------------------------------------------------
--NDB Navaids used for IAPs for an airport
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
    --,AirportIdentifier
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
--Create lines for all procedures.  Doesn't look quite right due to the fact that
-- these types of steps in the procedure don't have associated fixes
-- "CA" -Course to an Altitude or CA Leg. Defines a specified course to a specific altitude at an unspecified position"
-- "CD" - Course to a DME Distance or CD Leg. Defines a specified course to a specific DME Distance which is from a specific database DME Navaid.
-- "CI" - Course to an Intercept or CI Leg. Defines a specified course to intercept a subsequent leg.
-- "VA" - Heading to an Altitude termination or VA Leg. Defines a specified heading to a specific Altitude termination at an unspecified position.
-- "VD" - Heading to a DME Distance termination or VD Leg. Defines a specified heading terminating at a specified DME Distance from a specific database DME Navaid.
-- "VI" - Heading to an Intercept or VI Leg. Defines a specified heading to intercept the subsequent leg at an unspecified position.
-- "VR" - Heading to a Radial  termination or VR Leg. Defines a specified heading to a specified radial from a specific database VOR Navaid.

.headers on
.mode csv
.output "iap-lines.csv"
-- .output "sid-lines.csv"
-- .output "star-lines.csv"

SELECT
    procedure._id
    , procedure.AirportIdentifier
    , procedure.SIDSTARApproachIdentifier
    , procedure.TransitionIdentifier
    , procedure.AirportIdentifier 
        || '.' 
        || procedure.SIDSTARApproachIdentifier 
        || '.' 
        || procedure.TransitionIdentifier 
            as unique_id
    , procedure.RouteType
    , COALESCE( term_fix.waypointLongitude_wgs84
                ,vhf.vorLongitude_wgs84
                ,ndb.ndbLongitude_wgs84
                ,grid.waypointLongitude_wgs84
                ,vhf.dmeLongitude_wgs84
                )
                    AS Longitude
    , COALESCE( term_fix.waypointLatitude_wgs84
                ,vhf.vorLatitude_wgs84
                ,ndb.ndbLatitude_wgs84
                ,grid.waypointLatitude_wgs84
                ,vhf.dmeLatitude_wgs84)
                    AS Latitude
    , 'linestring ('
        || GROUP_CONCAT(
                COALESCE(    term_fix.waypointLongitude_wgs84
                            ,vhf.vorLongitude_wgs84
                            ,ndb.ndbLongitude_wgs84
                            ,grid.waypointLongitude_wgs84
                            ,vhf.dmeLongitude_wgs84)
            || ' '
            || COALESCE(    term_fix.waypointLatitude_wgs84
                            ,vhf.vorLatitude_wgs84
                            ,ndb.ndbLatitude_wgs84
                            ,grid.waypointLatitude_wgs84
                            ,vhf.dmeLatitude_wgs84) 
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
            procedure.FixIdentifier = grid.waypointIdentifier
              AND
            procedure.IcaoCode_1 = grid.IcaoCode_2
            
LEFT OUTER JOIN
    "primary_P_C_base_Airport - Terminal Waypoints" AS term_fix
        ON
            procedure.AirportIdentifier = term_fix.RegionCode
                AND
            procedure.FixIdentifier = term_fix.waypointIdentifier
                AND 
            procedure.IcaoCode_1 = term_fix.IcaoCode_2

LEFT OUTER JOIN
    "primary_D__base_Navaid - VHF Navaid" AS vhf
        ON     
            procedure.WaypointDescriptionCode1 = 'V'
                AND
            procedure.IcaoCode_1 = vhf.IcaoCode_2
                AND
            procedure.FixIdentifier = vhf.vorIdentifier

LEFT OUTER JOIN
    "primary_P_N_base_Airport - Terminal NDB" AS ndb
        ON
            procedure.WaypointDescriptionCode1 = 'N'
                AND
            procedure.IcaoCode_1 = ndb.IcaoCode_2
                AND
            procedure.FixIdentifier = ndb.ndbIdentifier
                AND
            procedure.AirportIdentifier = ndb.AirportIcaoIdentifier

LEFT OUTER JOIN
    "primary_P_G_base_Airport - Runways" AS rwy
        ON
            procedure.WaypointDescriptionCode1 = 'G'
                AND
            procedure.FixIdentifier = rwy.runwayIdentifier
                AND
            procedure.AirportIdentifier = rwy.AirportIcaoIdentifier
WHERE
--     procedure.AirportIdentifier LIKE '%CAE%'
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
    , procedure.AirportIdentifier
    , procedure.SIDSTARApproachIdentifier
    , procedure.TransitionIdentifier
    , procedure.AirportIdentifier 
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
                ,grid.waypointLongitude_wgs84
                ,vhf.dmeLongitude_wgs84
                )
                    AS Longitude
    , COALESCE( term_fix.waypointLatitude_wgs84
                ,vhf.vorLatitude_wgs84
                ,ndb.ndbLatitude_wgs84
                ,grid.waypointLatitude_wgs84
                ,vhf.dmeLatitude_wgs84)
                    AS Latitude
    , 'point( ' 
        || COALESCE(    term_fix.waypointLongitude_wgs84
                        ,vhf.vorLongitude_wgs84
                        ,ndb.ndbLongitude_wgs84
                        ,grid.waypointLongitude_wgs84
                        ,vhf.dmeLongitude_wgs84)
        || ' '
        || COALESCE(    term_fix.waypointLatitude_wgs84
                        ,vhf.vorLatitude_wgs84
                        ,ndb.ndbLatitude_wgs84
                        ,grid.waypointLatitude_wgs84
                        ,vhf.dmeLatitude_wgs84) 
        || ' )' 
            AS geometry

FROM
    "primary_P_F_base_Airport - Approach Procedures" AS procedure
    --, 'primary_P_E_base_Airport - STARs' AS procedure
    --, 'primary_P_D_base_Airport - SIDs' AS procedure

LEFT OUTER JOIN
    "primary_E_A_base_Enroute - Grid Waypoints" AS grid
        ON 
            procedure.FixIdentifier = grid.waypointIdentifier
             AND
            procedure.IcaoCode_1 = grid.IcaoCode_2

LEFT OUTER JOIN
    "primary_P_C_base_Airport - Terminal Waypoints" AS term_fix
        ON
            procedure.AirportIdentifier = term_fix.RegionCode
                AND
            procedure.FixIdentifier = term_fix.waypointIdentifier
                AND 
            procedure.IcaoCode_1 = term_fix.IcaoCode_2

LEFT OUTER JOIN
    "primary_D__base_Navaid - VHF Navaid" AS vhf
        ON     
            procedure.WaypointDescriptionCode1 = 'V'
                AND
            procedure.IcaoCode_1 = vhf.IcaoCode_2
                AND
            procedure.FixIdentifier = vhf.vorIdentifier

LEFT OUTER JOIN
    "primary_P_N_base_Airport - Terminal NDB" AS ndb
        ON
            procedure.WaypointDescriptionCode1 = 'N'
                AND
            procedure.IcaoCode_1 = ndb.IcaoCode_2
                AND
            procedure.FixIdentifier = ndb.ndbIdentifier
                AND
            procedure.AirportIdentifier = ndb.AirportIcaoIdentifier

LEFT OUTER JOIN
    "primary_P_G_base_Airport - Runways" AS rwy
        ON 
            procedure.WaypointDescriptionCode1 = 'G'
                AND
            procedure.FixIdentifier = rwy.runwayIdentifier
                AND
            procedure.AirportIdentifier = rwy.AirportIcaoIdentifier


WHERE
--     procedure.AirportIdentifier LIKE '%NUQ%'
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