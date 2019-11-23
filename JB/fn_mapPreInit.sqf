JBMAP_InstallDisplayControlDrawHandler =
{
	_this spawn
	{
		params ["_displays", "_displayNumber", "_controlNumber", "_handler", "_monitor"];

		scriptName "JBMAP_InstallDisplayControlDrawHandler";

		disableSerialization;

		private _displayName = format ["Display #%1", _displayNumber];

		while { true } do
		{
			private _display = displayNull;
			private _control = controlNull;
			while { isNull _control } do
			{
				sleep 1.0;
				{
					if (str _x == _displayName) then { _control = _x displayCtrl _controlNumber };
				} forEach ([] call _displays);
			};

			_control ctrlAddEventHandler ["Draw", _handler];

			if (not _monitor) exitWith {};

			while { not isNull _control } do
			{
				sleep 1.0;
			};
		};
	};
};

JBMAP_InitializeOverlay =
{
	_this spawn
	{
		params ["_mapDraw", "_gpsDraw"];

		scriptName "InstallMapDrawHandlers";

		[{ allDisplays }, 12, 51, _mapDraw, false] call JBMAP_InstallDisplayControlDrawHandler; // Main map
		[{ allDisplays }, 160, 51, _mapDraw, true] call JBMAP_InstallDisplayControlDrawHandler; // UAV
		[{ allDisplays }, -1, 500, _mapDraw, true] call JBMAP_InstallDisplayControlDrawHandler; // Artillery
		[{ allDisplays }, 312, 50, _mapDraw, true] call JBMAP_InstallDisplayControlDrawHandler; // Curator

		[{ uiNamespace getVariable "IGUI_Displays" }, 311, 101, _gpsDraw, false] call JBMAP_InstallDisplayControlDrawHandler; // GPS
	};
};
