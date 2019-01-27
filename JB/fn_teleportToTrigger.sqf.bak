/*

Teleport the player to a random position within the specified trigger area.

[trigger, message, direction] call JB_fnc_teleportToTrigger;

	- trigger (required), the trigger area to teleport into
	- message (optional), the message to show the player during teleport.  If
		not specified, no message is shown.
	- direction (optional), an object or numeric direction to face the player.
		If not specified, the player's direction is unchanged.

[MyTrigger, "Teleporting to base..."] call JB_fnc_teleportToTrigger;

*/

private _destinationTrigger = param [0, objNull, [objNull]];
private _destinationMessage = param [1, "", [""]];
private _destinationDirection = param [2, objNull, [objNull, 0]];

if (isNull _destinationTrigger) exitWith { false };

private _triggerPosition = getPosASL _destinationTrigger;
private _triggerArea = triggerArea _destinationTrigger;
private _sizeY = _triggerArea select 0;
private _sizeX = _triggerArea select 1;
private _angle = _triggerArea select 2;

// Get a random position in an unrotated trigger at the origin
private _parametricX = ((random 2.0) - 1.0) * _sizeX;
private _parametricY = ((random 2.0) - 1.0) * _sizeY;

private _sin = sin(_angle);
private _cos = cos(_angle);

// Rotate the basic position and translate it to the trigger's location
private _positionX = (_parametricX * _cos - _parametricY * _sin) + (_triggerPosition select 0);
private _positionY = (_parametricY * _cos + _parametricX * _sin) + (_triggerPosition select 1);

[[_positionX, _positionY, _triggerPosition select 2], _destinationDirection, _destinationMessage] spawn
{
	params ["_destinationPosition", "_destinationDirection", "_destinationMessage"];

	if (_destinationMessage != "") then
	{
		[_destinationMessage, 1] call JB_fnc_showBlackScreenMessage;
		sleep 0.5;
	};

	player setPosASL _destinationPosition;

	if (typeName _destinationDirection == "object") then
	{
		if (not isNull _destinationDirection) then
		{
			player setDir (player getRelDir _destinationDirection) + (getDir player);
		};
	}
	else
	{
		player setDir _destinationDirection;
	};
};

true