#include "\a3\editor_f\Data\Scripts\dikCodes.h"

#define CHANNEL_NONE -1
#define CHANNEL_GLOBAL 0
#define CHANNEL_SIDE 1
#define CHANNEL_COMMAND 2
#define CHANNEL_GROUP 3
#define CHANNEL_VEHICLE 4
#define CHANNEL_DIRECT 5
#define CHANNEL_CUSTOM1 6
#define CHANNEL_CUSTOM2 7
#define CHANNEL_CUSTOM3 8
#define CHANNEL_CUSTOM4 9
#define CHANNEL_CUSTOM5 10
#define CHANNEL_CUSTOM6 11
#define CHANNEL_CUSTOM7 12
#define CHANNEL_CUSTOM8 13
#define CHANNEL_CUSTOM9 14
#define CHANNEL_CUSTOM10 15

Radio_Enabled = false;

Radio_DisabledConfiguration = [CHANNEL_NONE, 0, false, false];

// [channel, max-range, make-click, make-noise, required-items]
Radio_ChannelConfigurations =
[
	[CHANNEL_GLOBAL, 0, [], false],
	[CHANNEL_SIDE, 0, [], false],
	[CHANNEL_COMMAND, 0, [], false],
	[CHANNEL_GROUP, 1000, ["Radio_ClickIn2a", "Radio_ClickOut2a"], false],
	[CHANNEL_VEHICLE, 1000, [], false],
	[CHANNEL_DIRECT, 0, [], false],
	[CHANNEL_CUSTOM1, 0, ["Radio_ClickIn2aLow", "Radio_ClickOut2aLow"], false],
	[CHANNEL_CUSTOM2, 0, ["Radio_ClickIn2aLow", "Radio_ClickOut2aLow"], false],
	[CHANNEL_CUSTOM3, 0, ["Radio_ClickIn2aLow", "Radio_ClickOut2aLow"], false],
	[CHANNEL_CUSTOM4, 0, ["Radio_ClickIn2aLow", "Radio_ClickOut2aLow"], false],
	[CHANNEL_CUSTOM5, 0, ["Radio_ClickIn2aLow", "Radio_ClickOut2aLow"], false],
	[CHANNEL_CUSTOM6, 0, ["Radio_ClickIn2aLow", "Radio_ClickOut2aLow"], false],
	[CHANNEL_CUSTOM7, 0, ["Radio_ClickIn2aLow", "Radio_ClickOut2aLow"], false],
	[CHANNEL_CUSTOM8, 0, ["Radio_ClickIn2aLow", "Radio_ClickOut2aLow"], false],
	[CHANNEL_CUSTOM9, 0, ["Radio_ClickIn2aLow", "Radio_ClickOut2aLow"], false],
	[CHANNEL_CUSTOM10, 0, ["Radio_ClickIn2aLow", "Radio_ClickOut2aLow"], false]
];

// Receiver support -----

// Determined by the sounds predefined in our CfgSounds.hpp file
#define MAX_NOISE_LEVEL 5

// How often to start a new noise track.  Clips are 5.7s long.  Lower numbers overlap noise tracks.
#define NOISE_DURATION (1.5 + random 0.5)

Radio_CS = call JB_fnc_criticalSectionCreate;
Radio_ActiveBroadcasts = [];

Radio_BroadcastBegin =
{
	_this spawn
	{
		params ["_configuration", "_sender"];

		private _channel = _configuration select 0;

		// If mic clicks should be played, play the depress click
		if (Radio_Enabled && count (_configuration select 2) > 0) then
		{
			playSound ((_configuration select 2) select 0);
		};

		Radio_CS call JB_fnc_criticalSectionEnter;

			private _broadcast = [_channel, _sender, true];
			Radio_ActiveBroadcasts pushBack _broadcast;

		Radio_CS call JB_fnc_criticalSectionLeave;

		// If no line noise, just wait.  Otherwise, keep the line noise going.
		if (not (_configuration select 3)) then
		{
			while { Radio_Enabled && (_broadcast select 2) } do // While broadcasting
			{
				sleep 0.1;
			};
		}
		else
		{
			private _source = "Land_HelipadEmpty_F" createVehicleLocal getPos player;
			_source attachTo [player, [-0.08, 0.35, 0.005], "Neck"];

			private _noiseDistanceQuantum = (_configuration select 1) / MAX_NOISE_LEVEL;

			private _wakeup = 0;
			private _noiseLevel = 0;
			private _noiseTrack = 0;
			private _distance = 0;
			while { Radio_Enabled && (_broadcast select 2) } do // While broadcasting
			{
				_distance = player distance _sender;
				_noiseLevel = (floor (_distance / _noiseDistanceQuantum)) min MAX_NOISE_LEVEL;
				_noiseTrack = (floor random 3) + 1;
				_source say2D format ["Radio_Noise%1_%2",  _noiseTrack, _noiseLevel];

				[{ not Radio_Enabled || not (_broadcast select 2) }, NOISE_DURATION] call JB_fnc_timeoutWaitUntil;
			};

			deleteVehicle _source;
		};

		// If mic clicks should be played, play the release click
		if (Radio_Enabled && count (_configuration select 2) > 0) then
		{
			playSound ((_configuration select 2) select 1);
		};

		Radio_CS call JB_fnc_criticalSectionEnter;

			private _index = -1;
			{
				if (_x select 0 == _channel && _x select 1 == _sender) exitWith { _index = _forEachIndex };
			} forEach Radio_ActiveBroadcasts;

			if (_index >= 0) then { Radio_ActiveBroadcasts deleteAt _index };

		Radio_CS call JB_fnc_criticalSectionLeave;
	};
};

Radio_BroadcastEnd =
{
	_this spawn
	{
		params ["_configuration", "_sender"];

		private _channel = _configuration select 0;

		Radio_CS call JB_fnc_criticalSectionEnter;

			private _broadcast = [];
			{
				if (_x select 0 == _channel && _x select 1 == _sender) exitWith { _broadcast = _x };
			} forEach Radio_ActiveBroadcasts;

		Radio_CS call JB_fnc_criticalSectionLeave;

		if (count _broadcast > 0) then { _broadcast set [2, false]; };
	};
};

// Sender support -----

Radio_Broadcasting = false;

Radio_Units =
{
	params ["_channel"];

	private _units = [];

	switch (_channel) do
	{
		case CHANNEL_GROUP:
		{
			_units = units group player;
		};
		case CHANNEL_VEHICLE:
		{
			_units = crew vehicle player;
		};
		case CHANNEL_COMMAND:
		{
			_units = (allPlayers select { _x == leader group _x });
		};
	};

	_units - [player]
};

Radio_Depress =
{
	Radio_Broadcasting = true;
};

Radio_Release =
{
	Radio_Broadcasting = false;
};

Radio_KeyDown =
{
	params ["_display", "_keyCode", "_shift", "_control", "_alt"];

	private _override = false;

	if (_keyCode == DIK_R && _shift && _control) then
	{
		Radio_Enabled = not Radio_Enabled;
		if (Radio_Enabled) then { systemchat "Ambient radio sounds enabled" } else { systemchat "Ambient radio sounds disabled" };
		_override = true;
	};

	if (not Radio_Broadcasting) then
	{
		if (_keyCode in actionKeys "PushToTalk" || { _keyCode in actionKeys "PushToTalkGroup" } || { _keyCode in actionKeys "PushToTalkVehicle" } || { _keyCode in actionKeys "PushToTalkCommand" }) then
		{
			[] call Radio_Depress;
		};
	};

	_override
};

Radio_KeyUp =
{
	if (not Radio_Broadcasting) exitWith {};

	params ["_display", "_keyCode", "_shift", "_control", "_alt"];

	if (_keyCode in actionKeys "PushToTalk" || { _keyCode in actionKeys "PushToTalkGroup" } || { _keyCode in actionKeys "PushToTalkVehicle" } || { _keyCode in actionKeys "PushToTalkCommand" }) then
	{
		[] call Radio_Release;
	};
};

Radio_ButtonDown =
{
	if (Radio_Broadcasting) exitWith {};

	params ["_display", "_keyCode", "_x", "_y", "_shift", "_control", "_alt"];

	_keyCode = _keyCode + 65536;

	if (_keyCode in actionKeys "PushToTalk" || { _keyCode in actionKeys "PushToTalkGroup" } || { _keyCode in actionKeys "PushToTalkVehicle" } || { _keyCode in actionKeys "PushToTalkCommand" }) then
	{
		[] call Radio_Depress;
	};
};

Radio_ButtonUp =
{
	if (not Radio_Broadcasting) exitWith {};

	params ["_display", "_keyCode", "_x", "_y", "_shift", "_control", "_alt"];

	_keyCode = _keyCode + 65536;

	if (_keyCode in actionKeys "PushToTalk" || { _keyCode in actionKeys "PushToTalkGroup" } || { _keyCode in actionKeys "PushToTalkVehicle" } || { _keyCode in actionKeys "PushToTalkCommand" }) then
	{
		[] call Radio_Release;
	};
};

#define UNIT_CHECK_INTERVAL 1.0
#define SLEEP_INTERVAL 0.1

Radio_EnableChannel =
{
	params ["_channel", "_enable"];

	// If there's no change to the channel do nothing
	if ((channelEnabled _channel) isEqualTo [_enable, _enable]) exitWith {};

	// If we're turning off the current channel, move to one that isn't completely disabled
	if (not _enable && _channel == currentChannel) then
	{
		private _newChannel = currentChannel;
		while { _newChannel = (_newChannel + 1) mod 6; (channelEnabled _newChannel) isEqualTo [false, false] && { _newChannel != currentChannel } } do {};
		setCurrentChannel _newChannel;
	};

	if (currentChannel == _channel) exitWith {}; // Cannot disable last usable channel

	// Make the change
	_channel enableChannel _enable;
};

Radio_Monitor =
{
	_this spawn
	{
		params ["_broadcastingConfiguration", "_broadcastingToUnits"];

		scriptName "spawnRadio_Monitor";

		private _currentToUnits = [];
		private _addedUnits = [];
		private _removedUnits = [];
		private _selectedConfiguration = _broadcastingConfiguration;

		private _nextUnitCheck = 0;

		while { true } do
		{
			_selectedConfiguration = if (Radio_Broadcasting) then { Radio_ChannelConfigurations select currentChannel } else { Radio_DisabledConfiguration };

			// Change of channel
			if (_broadcastingConfiguration select 0 != _selectedConfiguration select 0) then
			{
				if (_broadcastingConfiguration select 1 > 0) then
				{
					{
						[_broadcastingConfiguration, player] remoteExec ["Radio_BroadcastEnd", _x];
					} forEach _broadcastingToUnits;
					_broadcastingToUnits = [];
				};

				_broadcastingConfiguration = _selectedConfiguration;

				if (_broadcastingConfiguration select 1 > 0) then
				{
					_broadcastingToUnits = [_broadcastingConfiguration select 0] call Radio_Units;
					{
						[_broadcastingConfiguration, player] remoteExec ["Radio_BroadcastBegin", _x];
					} forEach _broadcastingToUnits;
				};
			};

			_nextUnitCheck = (_nextUnitCheck - 1) max 0;

			// Change of receiving units
			if (Radio_Broadcasting && _nextUnitCheck == 0) then
			{
				_nextUnitCheck = UNIT_CHECK_INTERVAL / SLEEP_INTERVAL;

				_currentToUnits = [_broadcastingConfiguration select 0] call Radio_Units;
				_addedUnits = _currentToUnits - _broadcastingToUnits;
				_removedUnits = _broadcastingToUnits - _currentToUnits;

				_noClickConfiguration = +_broadcastingConfiguration;
				_noClickConfiguration set [2, []];

				{
					[_noClickConfiguration, player] remoteExec ["Radio_BroadcastBegin", _x];
				} forEach _addedUnits;

				{
					[_noClickConfiguration, player] remoteExec ["Radio_BroadcastEnd", _x];
				} forEach _removedUnits;

				_broadcastingToUnits = _currentToUnits;
			};

			sleep SLEEP_INTERVAL;
		};

		_this call Radio_Monitor; // Keep going despite script looping limits
	};
};

[Radio_DisabledConfiguration, []] call Radio_Monitor;

Radio_InstallHandlers =
{
	params ["_displayNumber"];

	(findDisplay _displayNumber) displayAddEventHandler ["KeyDown", Radio_KeyDown];
	(findDisplay _displayNumber) displayAddEventHandler ["KeyUp", Radio_KeyUp];
	(findDisplay _displayNumber) displayAddEventHandler ["MouseButtonDown", Radio_ButtonDown];
	(findDisplay _displayNumber) displayAddEventHandler ["MouseButtonUp", Radio_ButtonUp];
};

[] spawn
{
	waitUntil { sleep 1; not isNull (findDisplay 46) };

	[46] call Radio_InstallHandlers;
};