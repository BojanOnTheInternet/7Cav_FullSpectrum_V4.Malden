AmmoFilter_TransferToTrolley =
{
	params ["_unit", "_candidate"];

	// Must load while in the loading bay
	if (not (_candidate inArea Base_Supply_Loading_Bay)) exitWith { false };

	// Candidate must be one of the free-standing khaki and yellow trolleys
	if ((typeOf _candidate) find "Land_PalletTrolley_01_" != 0) exitWith { false };

	true;
};

AmmoFilter_TransferInLoadingBay =
{
	params ["_unit", "_candidate"];

	// Must load while in the loading bay
	if (not (_candidate inArea Base_Supply_Loading_Bay)) exitWith { false };

	// Khaki and yellow trolleys are permitted
	if ((typeOf _candidate) find "Land_PalletTrolley_01_" == 0) exitWith { true };

	// Ammo boxes attached to the current player are permitted
	if (attachedTo _candidate == player && [_candidate] call JBA_IsAmmoBox) exitWith { true };

	false
};

AmmoFilter_TransferToAny =
{
	params ["_unit", "_candidate"];

	true;
};

TaruPod_AnimateDoors =
{
	params ["_vehicle", "_value"];

	_vehicle animate ["door_4_handle_rot", _value];
	_vehicle animate ["door_4_move_1", _value];
	_vehicle animate ["door_4_move_2", _value];

	_vehicle animate ["door_5_handle_rot", _value];
	_vehicle animate ["door_5_move_1", _value];
	_vehicle animate ["door_5_move_2", _value];

	_vehicle animateDoor ["door_6_source", _value];
};

Radio_Radios =
[
	["O_UavTerminal", "LOW", [242/255, 173/255, 89/255, 1.0], [["30.0MHz", 30.0], ["31.5MHz", 31.5], ["33.0MHz", 33.0], ["34.5MHz", 34.5], ["36.0MHz", 36.0]], "User2"],
	["I_UavTerminal", "HIGH", [242/255, 89/255, 89/255, 1.0], [["53.0MHz", 53.0], ["54.5MHz", 54.4], ["56.0MHz", 56.0], ["57.5.0MHz", 57.5], ["59.0MHz", 59.0]], "User3"]
];

Params_GetParamValue =
{
	params ["_name"];

	private _override = format ["PARAMS_%1_Override", _name];
	if (isNil _override) exitWith { [_name] call BIS_fnc_getParamValue };

	call compile _override;
};