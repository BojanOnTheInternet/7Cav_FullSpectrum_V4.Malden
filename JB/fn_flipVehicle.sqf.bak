private _vehicle = param [0, objNull, [objNull]];

[_vehicle] spawn
{
	params ["_vehicle"];

	titleText ["Please stand back.  Vehicle flipping in 2 seconds.", "plain", 0.2];
	sleep 2;
	[_vehicle] remoteExec ["JB_FV_Flip", _vehicle, false];
};