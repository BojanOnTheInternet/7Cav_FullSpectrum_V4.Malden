// Base trash
{
	((_x select 0) nearestObject (_x select 1)) hideObject true;
} forEach
[
	[[8122,10128,0], 168704],
	[[8194,10293,0], 167258],
	[[8193,10155,0], 167646],
	[[8202,10231,0], 167529]
];

// Infantry spawn exit door
{
	_x animateSource ["door_2_sound_source", 1];
} forEach [[8133,10123,0] nearestobject 168702];