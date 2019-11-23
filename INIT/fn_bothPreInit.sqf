MASS_TO_KG = 0.04545;

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

BOTH_IsSpecOpsMember =
{
	params ["_player"];
	
	_player getVariable ["SPM_SpecialOperations", false];
};
