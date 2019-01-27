#define SPACING 0.01

Diagnostics_StripCharts = []; // [[name, [display]], ...]

Diagnostics_CreateStripChart =
{
	params ["_name"];

	private _index = [Diagnostics_StripCharts, _name] call BIS_fnc_findInPairs;
	if (_index != -1) exitWith { displayNull };

	private _index = [Diagnostics_StripCharts, ""] call BIS_fnc_findInPairs;
	if (_index == -1) then { _index = count Diagnostics_StripCharts; Diagnostics_StripCharts pushBack ["", [displayNull]] };

	Diagnostics_StripCharts select _index set [0, _name];

	_name cutRsc ["Diagnostics_StripChart", "plain"];
	private _display = uiNameSpace getVariable "Diagnostics_StripChart";

	Diagnostics_StripCharts select _index set [1, [_display]];

	private _lineControl = _display displayCtrl 1000;
	private _backgroundPosition = ctrlPosition _lineControl;
	_backgroundPosition set [1, (_backgroundPosition select 1) + (((_backgroundPosition select 3) + SPACING) * _index)];
	_lineControl ctrlSetPosition _backgroundPosition;
	_lineControl ctrlCommit 0;

	_display
};

Diagnostics_DeleteStripChart =
{
	params ["_name"];

	private _index = [Diagnostics_StripCharts, _name] call BIS_fnc_findInPairs;
	if (_index == -1) exitWith { };

	_name cutText ["", "plain", 0, false];

	Diagnostics_StripCharts set [_index, ["", [displayNull]]];
};

Diagnostics_StripChartExists =
{
	params ["_name"];

	([Diagnostics_StripCharts, _name] call BIS_fnc_findInPairs != -1)
};

Diagnostics_FeedStripChart =
{
	_this spawn
	{
		params ["_display", "_title", "_color", "_min", "_max", "_numberSamples", "_sampleInterval", "_sampleFunction"];

		private _feeds = _display getVariable "Diagnostics_StripCharts_Feeds";
		if (isNil "_feeds") then
		{
			_feeds = [10000, []];
			_display setVariable ["Diagnostics_StripCharts_Feeds", _feeds];
		};

		private _controlIDC = _feeds select 0;
		_feeds set [0, _controlIDC + _numberSamples + 1];
		(_feeds select 1) pushBack _title;

		private _titleControl = 0;
		private _lineControl = 0;

		private _backgroundPosition = ctrlPosition (_display displayCtrl 1000);
		private _backgroundX = _backgroundPosition select 0;
		private _backgroundY = _backgroundPosition select 1;
		private _backgroundWidth = _backgroundPosition select 2;
		private _backgroundHeight = _backgroundPosition select 3;

		private _fontHeight = 0.03;

		_titleControl = _display ctrlCreate ["RscText", _controlIDC];
		_titleControl ctrlSetText format [_title, _min];
		_titleControl ctrlSetTextColor _color;
		_titleControl ctrlSetFontHeight _fontHeight;
		_titleControl ctrlSetBackgroundColor [0,0,0,0];
		_titleControl ctrlSetPosition [_backgroundX, _backgroundY + _backgroundHeight - _fontHeight * count (_feeds select 1), 0.5, _fontHeight];
		_titleControl ctrlCommit 0;

		private _spacing = _backgroundWidth / (_numberSamples - 1);

		private _samples = [_min];
		for "_i" from 2 to _numberSamples do
		{
			_samples pushBack _min;

			_lineControl = _display ctrlCreate ["RscLine", _controlIDC + _i];
			_lineControl ctrlSetPixelPrecision 2;
			_lineControl ctrlSetTextColor _color;
			_lineControl ctrlSetPosition [_backgroundX + (_i - 2) * _spacing, 0, _spacing, 0];
			_lineControl ctrlCommit 0;
		};
	
		private _range = _max - _min;
		private _sampleValue = 0.0;
		private _prevY = 0;
		private _nextY = 0;
		private _change = 0;
		private _line = [];
		private _updateMin = 0;
		private _updateMax = 0;
		private _updateRange = 0;

		["start"] call _sampleFunction;

		while { not isNull _display } do
		{
			sleep _sampleInterval;

			_sampleValue = ["sample"] call _sampleFunction;
			if (isNil "_sampleValue") exitWith {};

			_samples deleteAt 0;
			_samples pushBack _sampleValue;

			_titleControl ctrlSetText format [_title, _sampleValue];

			_updateMin = _min;
			_updateMax = _max;
			{ if (_x < _updateMin) then { _updateMin = _x }; if (_x > _updateMax) then { _updateMax = _x } } forEach _samples;
			_updateRange = _updateMax - _updateMin;

			_prevY = -1e10;
			for "_i" from 1 to _numberSamples do
			{
				_nextY = _backgroundY + _backgroundHeight * (1.0 - ((_samples select (_i - 1)) - _updateMin) / _updateRange);

				if (_prevY != -1e10) then
				{
					_lineControl = _display displayCtrl (_controlIDC + _i);

					_line = ctrlPosition _lineControl;
					_line set [1, _prevY];
					_line set [3, _nextY - _prevY];

					_lineControl ctrlSetPosition _line;
					_lineControl ctrlCommit 0;
				};

				_prevY = _nextY;
			};
		};

		["stop"] call _sampleFunction;
	};
};

Diagnostics_Sample_DisplayFrameRate =
{
	round diag_fps
};

Diagnostics_Sample_NumberPlayers =
{
	count (allPlayers select { not (_x isKindOf "HeadlessClient_F") })
};

Diagnostics_Sample_C_ServerFrameRate =
{
	Diagnostics_ServerFrameRate = _this select 0;
};

Diagnostics_Sample_S_ServerFrameRate =
{
	[round diag_fps] remoteExec ["Diagnostics_Sample_C_ServerFrameRate", remoteExecutedOwner]
};

Diagnostics_ServerFrameRate = 0;
Diagnostics_Sample_ServerFrameRate =
{
	[] remoteExec ["Diagnostics_Sample_S_ServerFrameRate", 2]; Diagnostics_ServerFrameRate
};