--VOR 
DROP INDEX IF EXISTS "primary_D__base_Navaid - VHF Navaid VORIdentifier Index";
        CREATE INDEX "primary_D__base_Navaid - VHF Navaid VORIdentifier Index"
                  ON "primary_D__base_Navaid - VHF Navaid" (VORIdentifier);

--------------------------------------------------------------------------------
--NDB
DROP INDEX IF EXISTS "primary_D_B_base_Navaid - NDB Navaid NDBIdentifier Index";
        CREATE INDEX "primary_D_B_base_Navaid - NDB Navaid NDBIdentifier Index"
	          ON "primary_D_B_base_Navaid - NDB Navaid" (NDBIdentifier); 

--------------------------------------------------------------------------------
--Terminal NDB
DROP INDEX IF EXISTS "primary_P_N_base_Airport - Terminal NDBIdentifier Index";
        CREATE INDEX "primary_P_N_base_Airport - Terminal NDBIdentifier Index"
                  ON "primary_P_N_base_Airport - Terminal NDB" (NDBIdentifier); 
--------------------------------------------------------------------------------
--Approach procedures
DROP INDEX IF EXISTS "primary_P_F_base_Airport - Approach Procedures FixIdentifier Index";
        CREATE INDEX "primary_P_F_base_Airport - Approach Procedures FixIdentifier Index"
	          ON "primary_P_F_base_Airport - Approach Procedures" (FixIdentifier); 
	
DROP INDEX IF EXISTS "primary_P_F_base_Airport - Approach Procedures LandingFacilityIcaoIdentifier Index";
        CREATE INDEX "primary_P_F_base_Airport - Approach Procedures LandingFacilityIcaoIdentifier Index"
	          ON "primary_P_F_base_Airport - Approach Procedures" (LandingFacilityIcaoIdentifier);

--------------------------------------------------------------------------------
--SIDs
DROP INDEX IF EXISTS "primary_P_D_base_Airport - SIDs FixIdentifier Index";
        CREATE INDEX "primary_P_D_base_Airport - SIDs FixIdentifier Index"
	          ON "primary_P_D_base_Airport - SIDs" (FixIdentifier); 
	
DROP INDEX IF EXISTS "primary_P_D_base_Airport - SIDs LandingFacilityIcaoIdentifier Index";
        CREATE INDEX "primary_P_D_base_Airport - SIDs LandingFacilityIcaoIdentifier Index"
	          ON "primary_P_D_base_Airport - SIDs" (LandingFacilityIcaoIdentifier);
	          
--------------------------------------------------------------------------------
--STARS
DROP INDEX IF EXISTS "primary_P_E_base_Airport - STARs FixIdentifier Index";
        CREATE INDEX "primary_P_E_base_Airport - STARs FixIdentifier Index"
	          ON "primary_P_E_base_Airport - STARs" (FixIdentifier); 
	
DROP INDEX IF EXISTS "primary_P_E_base_Airport - STARs LandingFacilityIcaoIdentifier Index";
        CREATE INDEX "primary_P_E_base_Airport - STARs LandingFacilityIcaoIdentifier Index"
	          ON "primary_P_E_base_Airport - STARs" (LandingFacilityIcaoIdentifier);
	          
--------------------------------------------------------------------------------
--Enroute fixes
DROP INDEX IF EXISTS "primary_E_A_base_Enroute - Grid Waypoints WaypointIdentifier Index";
        CREATE INDEX "primary_E_A_base_Enroute - Grid Waypoints WaypointIdentifier Index"
	          ON "primary_E_A_base_Enroute - Grid Waypoints" (WaypointIdentifier);
	
DROP INDEX IF EXISTS "primary_E_A_base_Enroute - Grid Waypoints WaypointLocation Index";
        CREATE INDEX "primary_E_A_base_Enroute - Grid Waypoints WaypointLocation Index"
	          ON "primary_E_A_base_Enroute - Grid Waypoints" (waypointLatitude_WGS84,waypointLongitude_WGS84);

--------------------------------------------------------------------------------
--Terminal fixes
DROP INDEX IF EXISTS "primary_P_C_base_Airport - Terminal Waypoints WaypointIdentifier Index";
        CREATE INDEX "primary_P_C_base_Airport - Terminal Waypoints WaypointIdentifier Index"
	          ON "primary_P_C_base_Airport - Terminal Waypoints" (WaypointIdentifier);
	
DROP INDEX IF EXISTS "primary_P_C_base_Airport - Terminal Waypoints LocationIndex";
        CREATE INDEX "primary_P_C_base_Airport - Terminal Waypoints LocationIndex"
	          ON "primary_P_C_base_Airport - Terminal Waypoints" (waypointLatitude_WGS84,waypointLongitude_WGS84);
	
--------------------------------------------------------------------------------
--Runways
DROP INDEX IF EXISTS "primary_P_G_base_Airport - Runways LandingFacilityIcaoIdentifier Index";
        CREATE INDEX "primary_P_G_base_Airport - Runways LandingFacilityIcaoIdentifier Index"
                  ON "primary_P_G_base_Airport - Runways" (LandingFacilityIcaoIdentifier);
                  
VACUUM;
