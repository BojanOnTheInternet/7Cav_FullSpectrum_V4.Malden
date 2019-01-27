// Main HQ double doors
{
	_x animate ["door_7a_move", 1];
	_x animate ["door_7b_move", 1];
	_x animate ["door_8a_move", 1];
	_x animate ["door_8b_move", 1];
} forEach [[14600, 16800, 0] nearestobject 458754, [14600, 16800, 0] nearestobject 493920];

// SpecOps HQ exit door
{
	_x animateSource ["door_2_sound_source", 1];
} forEach [[15210,17330,0] nearestobject 490995];