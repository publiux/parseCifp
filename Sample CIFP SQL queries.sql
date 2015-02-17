---Minimum Safe Altitudes at an airport\
.headers on
select
  *
from 
  "primary_P_S_base_Airport - MSA" as msa
WHERE 
  --msa.AirportIdentifier like '%RIC%'
  msa.AirportIdentifier IN ('KOFP')
  ;
------------------------------------------------------------------
--SIDs at an airport
explain query plan
select distinct
  sids.AirportIdentifier
  ,sids.SIDSTARApproachIdentifier
  
from 
        "primary_P_D_base_Airport - SIDs" as sids

WHERE 
        sids.AirportIdentifier = 'KRIC' 
       ;
------------------------------------------------------------------
--STARs at an airport
select distinct
  stars.AirportIdentifier
  ,stars.SIDSTARApproachIdentifier
  
from 
        "primary_P_E_base_Airport - STARs" as stars

WHERE 
        stars.AirportIdentifier like '%RIC%' 
        ;
------------------------------------------------------------------        
--IAPs (all steps) at an airport
select *
  --iap.AirportIdentifier
  --,iap.SIDSTARApproachIdentifier
  
from 
        "primary_P_F_base_Airport - Approach Procedures" as IAP

WHERE 
        iap.AirportIdentifier like '%OFP%' 
        ;

------------------------------------------------------------------
--IAPs at an airport
select distinct
  iap.AirportIdentifier
  ,iap.SIDSTARApproachIdentifier
  
from 
        "primary_P_F_base_Airport - Approach Procedures" as IAP

WHERE 
        iap.AirportIdentifier like '%RIC%' 
        ;

------------------------------------------------------------------
--Runways at an airport
select distinct
	rwy.AirportICAOIdentifier
	,rwy.RunwayIdentifier
	,rwy.RunwayLatitude
        ,rwy.RunwayLongitude
from 
        "primary_P_G_base_Airport - Runways" as RWY

WHERE 
        rwy.AirportICAOIdentifier like '%RIC%' ;
------------------------------------------------------------------        
--Longest runway's length at an airport (in hundreds of feet.  eg 090 = 9000')
select distinct
	rwy.AirportICAOIdentifier
	,rwy.LongestRunway
 
from 
        "primary_P_A_base_Airport - Reference Points" as RWY

WHERE 
        rwy.AirportICAOIdentifier in ('KRIC', 'KDCA', 'KIAD', 'KORF') ;
-------------------------------------------------------------------
--NDB Navaids used for IAPs for an airport
select distinct
        iap.FixIdentifier	
	,NDB.NDBLatitude
	,NDB.NDBLongitude
from 
        "primary_P_F_base_Airport - Approach Procedures" as IAP

JOIN
	"primary_D_B_base_Navaid - NDB Navaid" as NDB

ON 
	iap.FixIdentifier = ndb.NDBIdentifier

WHERE 
        airportidentifier like '%RIC%' ;
------------------------------------------------------------------
--VHF Navaids used for IAPs for an airport
select distinct
        iap.FixIdentifier	
	,VOR.VORLatitude
	,VOR.VORLongitude
from 
        "primary_P_F_base_Airport - Approach Procedures" as IAP

JOIN
	"primary_D__base_Navaid - VHF Navaid" as VOR

ON 
	iap.FixIdentifier = vor.vorIdentifier

WHERE 
        airportidentifier like '%RIC%' ;
------------------------------------------------------------------
--Fixes used for IAPs for an airport
select distinct
        iap.FixIdentifier	
	,fix.waypointLatitude
	,fix.waypointLongitude
from 
        "primary_P_F_base_Airport - Approach Procedures" as IAP

JOIN
	"primary_E_A_base_Enroute - Grid Waypoints" as FIX

ON 
	iap.FixIdentifier = fix.waypointIdentifier

WHERE 
        airportidentifier like '%RIC%' ;
------------------------------------------------------------------
--Terminal waypoints used for IAPs for an airport
select distinct
        iap.FixIdentifier	
	,fix.waypointLatitude
	,fix.waypointLongitude
from 
        "primary_P_F_base_Airport - Approach Procedures" as IAP

JOIN
	"primary_P_C_base_Airport - Terminal Waypoints" as FIX

ON 
	iap.FixIdentifier = fix.waypointIdentifier

WHERE 
        airportidentifier like '%RIC%' ;


------------------------------------------------------------------
--Terminal waypoints used for IAPs for a heliport
select distinct
        iap.FixIdentifier	
	,fix.waypointLatitude
	,fix.waypointLongitude
from 
        "primary_H_F_base_Heliport - Approach Procedures" as IAP

JOIN
	"primary_E_A_base_Enroute - Grid Waypoints" as FIX

ON 
	iap.FixIdentifier = fix.waypointIdentifier

WHERE 
        HeliportIdentifier like '%RIC%' ;
------------------------------------------------------------------
select 
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

from 
--        "primary_P_F_base_Airport - Approach Procedures "
	"primary_H_F_base_Heliport - Approach Procedures"
WHERE 
        --airportidentifier like '%02p%' 
	heliportidentifier like '%02p%' 
ORDER BY 
        SidstarApproachIdentifier,TransitionIdentifier,SequenceNumber;
------------------------------------------------------------------
select 
        *	
from 
	"primary_H_F_base_Heliport - Approach Procedures"
WHERE
	heliportidentifier like '%02P%' ;
