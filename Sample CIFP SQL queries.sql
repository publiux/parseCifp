-- If you feel like outputting query results to CSV:
-- sqlite3 cifp-1513.db
-- .headers on
-- .mode csv
-- .output filename.csv

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
    ,WaypointDescriptionCode
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
-- Or just the interesting parts of MSA
SELECT
    _id
    ,AirportIdentifier
    ,MagneticTrueIndicator
    ,MSACenter
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
FROM
    "primary_P_S_base_Airport - MSA" AS msa

WHERE
    --msa.AirportIdentifier LIKE  '%RIC%'
    msa.AirportIdentifier IN ('KART')
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
    --,WaypointDescriptionCode

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
