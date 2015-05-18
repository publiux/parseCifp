DROP INDEX IF EXISTS "primary_P_F_base_Airport-ApproachProceduresFixIdentifierIndex";
CREATE INDEX "primary_P_F_base_Airport-ApproachProceduresFixIdentifierIndex"
	on "primary_P_F_base_Airport - Approach Procedures" (FixIdentifier); 

DROP INDEX IF EXISTS "primary_E_A_base_Enroute-GridWaypointsWaypointLocationIndex";
CREATE INDEX "primary_E_A_base_Enroute-GridWaypointsWaypointLocationIndex"
	on "primary_E_A_base_Enroute - Grid Waypoints" (waypointLatitude,waypointLongitude); 	
	
	
DROP INDEX IF EXISTS "primary_P_C_base_Airport-TerminalWaypointsLocationIndex";
CREATE INDEX "primary_P_C_base_Airport-TerminalWaypointsLocationIndex"
	on "primary_P_C_base_Airport - Terminal Waypoints" (waypointLatitude,waypointLongitude);
	
       