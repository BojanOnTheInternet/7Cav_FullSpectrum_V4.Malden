if (not hasInterface) exitWith {};

// If the client is also the server (i.e. an editor session), just hide the markers.  But normally, delete them off the client, where they have no purpose
if (isServer) then
{
	{ _x setMarkerAlphaLocal 0 } forEach (allMapMarkers select { _x find "SPM_INFLUENCE_" == 0 });
	{ _x setMarkerAlphaLocal 0 } forEach (allMapMarkers select { _x find "SPM_MO_" == 0 });
}
else
{
	{ deleteMarkerLocal _x } forEach (allMapMarkers select { _x find "SPM_INFLUENCE_" == 0 });
	{ deleteMarkerLocal _x } forEach (allMapMarkers select { _x find "SPM_MO_" == 0 });
};
