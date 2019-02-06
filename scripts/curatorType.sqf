_isZeus = false;
{
	_isZeus = (_caller == (getAssignedCuratorUnit _x));
if(_isZeus) exitWith {true};
} forEach allCurators;

// If the player is in a zeus slot then they are a GM
if(_isZeus) exitWith { "GM" };
""
