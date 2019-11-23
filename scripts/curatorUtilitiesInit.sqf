#include "\a3\editor_f\Data\Scripts\dikCodes.h"

CuratorUtilities_LightOn = false;
CuratorUtilities_LightLight = objNull;

CuratorUtilities_Light =
{
	if (isNull CuratorUtilities_LightLight) then
	{
		CuratorUtilities_LightLight = "#lightpoint" createvehiclelocal [0,0,0];
		CuratorUtilities_LightLight setLightDayLight true;
		CuratorUtilities_LightLight setLightBrightness 0;
		CuratorUtilities_LightLight setLightAmbient [0.0, 0.0, 0.0];
		CuratorUtilities_LightLight setLightColor [1.0, 1.0, 1.0];
		CuratorUtilities_LightLight setLightAttenuation [5000, 2, 1, 1];

		addMissionEventHandler ["EachFrame",
			{
				private _cameraPosition = getPos curatorCamera;

				if (CuratorUtilities_LightOn && (_cameraPosition select 0) != 0) then
				{
					_cameraPosition set [2, 400];

					CuratorUtilities_LightLight setLightBrightness 0.6;
					CuratorUtilities_LightLight setPos _cameraPosition;
				}
				else
				{
					CuratorUtilities_LightLight setLightBrightness 0;
				};
			}];
	};

	CuratorUtilities_LightOn = not CuratorUtilities_LightOn;
};

CuratorUtilities_KeyDownHandler =
{
	params ["_control", "_key", "_isShift", "_isControl", "_isAlt"];

	private _override = false;

	// CTRL+SHIFT+D followed by a key (control, shift and D will continue to come in as _key while the player holds any of them down)
	if (CuratorUtilities_WaitingForDiagnosticsKey && not (_key in [DIK_D, DIK_LCONTROL, DIK_LSHIFT, DIK_RCONTROL, DIK_RSHIFT])) exitWith
	{
		CuratorUtilities_WaitingForDiagnosticsKey = false;

		switch (_key) do
		{
			case DIK_I:
			{
				if (CLIENT_CuratorType in ["MC"]) then
				{
					_override = true;
					[] call OP_Inspector_ShowDialog;
				};
			};

			case DIK_F:
			{
				if (CLIENT_CuratorType in ["MC"]) then
				{
					_override = true;

					if (["DisplayFrameRate"] call Diagnostics_StripChartExists) then
					{
						["DisplayFrameRate"] call Diagnostics_DeleteStripChart;
					}
					else
					{
						disableSerialization;
						private _display = ["DisplayFrameRate"] call Diagnostics_CreateStripChart;
						[_display, "CLIENT FPS - %1", [1,1,1,1], 0.0, 80.0, 100, 0.2, Diagnostics_Sample_DisplayFrameRate] call Diagnostics_FeedStripChart;
					};
				}
			};

			case DIK_S:
			{
				if (CLIENT_CuratorType in ["MC"]) then
				{
					_override = true;

					if (["ServerFrameRate"] call Diagnostics_StripChartExists) then
					{
						["ServerFrameRate"] call Diagnostics_DeleteStripChart;
					}
					else
					{
						disableSerialization;
						private _display = ["ServerFrameRate"] call Diagnostics_CreateStripChart;
						[_display, "SERVER FPS - %1", [1,1,0,1], 0.0, 55.0, 100, 0.2, Diagnostics_Sample_ServerFrameRate] call Diagnostics_FeedStripChart;
					};
				};
			};

			case DIK_P:
			{
				if (CLIENT_CuratorType in ["MC"]) then
				{
					_override = true;

					if (["NumberPlayers"] call Diagnostics_StripChartExists) then
					{
						["NumberPlayers"] call Diagnostics_DeleteStripChart;
					}
					else
					{
						disableSerialization;
						private _display = ["NumberPlayers"] call Diagnostics_CreateStripChart;
						[_display, "PLAYERS - %1", [0,1,0,1], 0.0, 10.0, 100, 5.0, Diagnostics_Sample_NumberPlayers] call Diagnostics_FeedStripChart;
					};
				};
			};
		};

		_override
	};

	switch (_key) do
	{
		case DIK_C:
		{
			if (CLIENT_CuratorType in ["MC"]) then
			{
				if (_isShift && _isControl) then
				{
					_override = true;
					[] call OP_Command_ShowDialog;
				};
			};
		};

		case DIK_D:
		{
			if (CLIENT_CuratorType in ["MC"]) then
			{
				if (_isShift && _isControl) then
				{
					_override = true;
					CuratorUtilities_WaitingForDiagnosticsKey = true;
				};
			};
		};

		case DIK_L:
		{
			if (CLIENT_CuratorType in ["MC", "MP"]) then
			{
				if (_isShift && _isControl) then
				{
					_override = true;
					[] call CuratorUtilities_Light;
				};
			};
		};

		case DIK_M:
		{
			if (CLIENT_CuratorType in ["MC"]) then
			{
				if (_isShift && _isControl) then
				{
					_override = true;
					[] spawn JB_MP_ShowParameterEditor;
				};
			};
		};
	};

	_override;
};

CuratorUtilities_WaitingForDiagnosticsKey = false;

waitUntil { sleep 1; not isNull (findDisplay 46) };
(findDisplay 46) displayAddEventHandler ["KeyDown", CuratorUtilities_KeyDownHandler];

while { true } do
{
	waitUntil { sleep 1; not isNull (findDisplay 312) };
	(findDisplay 312) displayAddEventHandler ["KeyDown", CuratorUtilities_KeyDownHandler];

	waitUntil { sleep 1; isNull (findDisplay 312) };
};