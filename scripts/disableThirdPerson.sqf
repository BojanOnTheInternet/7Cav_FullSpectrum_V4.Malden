["PersonView", {true}, {true}, {true}] call CLIENT_OverrideAction;

// Handlers are not currently fired when the player has a display or dialog visible (ARMA 1.80)
[] spawn
{
	while { true } do
	{
		if (cameraView == "EXTERNAL") then { player switchCamera "INTERNAL" };
		sleep 1;
	};
};