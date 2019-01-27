PARADROP_Line =
{
	params ["_name", "_color"];

//	format ["<img size='1.0' color='#aa%2' image='a3\ui_f\data\Map\VehicleIcons\iconObject_circle_CA.paa'/> <t size='0.80' color='#aaffffff'>%1</t><br/>", _name, _color];
	format ["<img size='1.0' color='#aa%2' image='a3\ui_f\data\IGUI\RscIngameUI\RscUnitInfoAirRTDFull\igui_WLight_INST_ca.paa'/> <t size='0.80' color='#aaffffff'>%1</t><br/>", _name, _color];
//	format ["<img size='1.0' color='#aa%2' image='a3\ui_f\data\GUI\Cfg\Ranks\major_gs.paa'/> <t size='0.80' color='#aaffffff'>%1</t><br/>", _name, _color];
//	format ["<img size='1.0' color='#aa%2' image='a3\ui_f\data\Map\MapControl\custommark_CA.paa'/> <t size='0.80' color='#aaffffff'>%1</t><br/>", _name, _color];
};

#define DISPLAY_UPDATE_INTERVAL 0.5

PARADROP_UpdateDisplay =
{
	params ["_vehicle"];

	disableSerialization;

	if (vehicle player != _vehicle || not (lifeState player in ["HEALTHY", "INJURED"])) then
	{
		("PARADROP_Layer" call BIS_fnc_rscLayer) cutText ["", "plain", 0, false];
	}
	else
	{
		("PARADROP_Layer" call BIS_fnc_rscLayer) cutRsc ["Paradrop", "plain", 0, false];
		private _crewList = (uiNameSpace getVariable "Paradrop") displayCtrl 1000;

		private _activeColor = "22ff22";
		private _inactiveColor = "ff2222";

		_text = "";

		_text = _text + (["Paradrop - HALO", if ([_vehicle] call Parachute_Aircraft_HALO_Condition) then { _activeColor } else { _inactiveColor }] call PARADROP_Line);
		_text = _text + (["Paradrop - Static line", if ([_vehicle] call Parachute_Aircraft_StaticLine_Condition) then { _activeColor } else { _inactiveColor }] call PARADROP_Line);

		_crewList ctrlSetStructuredText parseText _text;
	};
};

PARADROP_StartDisplay =
{
	if (!canSuspend) then
	{
		_this spawn PARADROP_StartDisplay;
	}
	else
	{
		private _vehicle = vehicle player;

		if (not (_vehicle getVariable ["Parachute_Paradrop", false])) exitWith {};

		while { vehicle player == _vehicle && (lifeState player in ["HEALTHY", "INJURED"]) } do
		{
			[_vehicle] call PARADROP_UpdateDisplay;

			sleep DISPLAY_UPDATE_INTERVAL;
		};

		[_vehicle] call PARADROP_UpdateDisplay;
	};
};

player addEventHandler ["GetInMan", PARADROP_StartDisplay];