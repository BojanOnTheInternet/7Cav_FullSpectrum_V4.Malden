#include "..\SPM\strongpoint.h"

#define MINIMIZE_DELAY_AFTER_SUCCESS 45

[] spawn
{
	private _mission = OO_NULL;
	private _position = [];
	private _radius = 0;
	private _selected = 0;

	scriptName "MonitorMissions";

	private _stopAbandonedMissions = // Also "minimize" missions that have completed, but haven't been abandoned by the players
	{
		params ["_players"];

		_mission = _x;
		if (OO_GET(_mission,Mission,MissionState) != "unresolved") then
		{
			_position = OO_GET(_mission,Strongpoint,Position);
			_radius = OO_GET(_mission,Strongpoint,ControlRadius);
			_abandoned = _players findIf { _position distance2D _x <= _radius } == -1;

			if (_abandoned) then
			{
				[] call OO_METHOD(_mission,Strongpoint,Stop);
				[_mission] call OP_S_NotifyRemovedMission;
			}
			else
			{
				if (OO_GET(_mission,Mission,MissionState) == "completed-success") then
				{
					private _resolvedTime = ["MissionMonitor_ResolvedTime"] call OO_METHOD(_mission,Strongpoint,GetTagValue);
					if (isNil "_resolvedTime") then { _resolvedTime = diag_tickTime; ["MissionMonitor_ResolvedTime", _resolvedTime] call OO_METHOD(_mission,Strongpoint,SetTagValue) };

					if (diag_tickTime - _resolvedTime > MINIMIZE_DELAY_AFTER_SUCCESS) then
					{
						["MissionMonitor_ResolvedTime", 1e30] call OO_METHOD(_mission,Strongpoint,SetTagValue);
						["minimize", 0] call OO_METHOD(_mission,Strongpoint,Command);
					};
				};
			};
		};
		false;
	};

	private _stopRunningMissions =
	{
		_mission = _x;
		if (OO_GET(_mission,Strongpoint,RunState) == "running") then
		{
			[] call OO_METHOD(_mission,Strongpoint,Stop);
			[_mission] call OP_S_NotifyRemovedMission;
		};
		//BUG: Prevent RunState=starting missions from getting going
		false;
	};

	private _deleteStoppedMissions =
	{
		_mission = _x;
		if (OO_GET(_mission,Strongpoint,RunState) == "stopped") then
		{
			call OO_DELETE(_mission);
		};
		false;
	};

	private _advanceState = ["Advance"] call JB_MP_GetParamValueText;

	while { true } do
	{
		private _advanceStateNew = ["Advance"] call JB_MP_GetParamValueText;

		if (_advanceStateNew != _advanceState) then
		{
			if (_advanceStateNew == "Started" && _advanceState == "Stopped") then { ["NotificationEndAdvance", ["An operational advance has been started by command."]] remoteExec ["BIS_fnc_showNotification", 0] };
			if (_advanceStateNew == "Started" && _advanceState == "Suspended") then { ["NotificationEndAdvance", ["The operational advance has been resumed by command."]] remoteExec ["BIS_fnc_showNotification", 0] };
			if (_advanceStateNew == "Stopped") then { ["NotificationEndAdvance", ["The operational advance has been stopped by command."]] remoteExec ["BIS_fnc_showNotification", 0] };
			if (_advanceStateNew == "Suspended" && _advanceState == "Started") then { ["NotificationEndAdvance", ["The operational advance has been suspended by command."]] remoteExec ["BIS_fnc_showNotification", 0] };
		};

		_advanceState = _advanceStateNew;

		if (_advanceState in ["Stopped", "Suspended"]) then
		{
			OO_FOREACHINSTANCE(MissionAdvance,[],_stopRunningMissions);
		}
		else
		{
			OO_FOREACHINSTANCE(MissionAdvance,[allPlayers],_stopAbandonedMissions);
		};

		OO_FOREACHINSTANCE(MissionAdvance,[],_deleteStoppedMissions);

		if (SpecialOperations_RunState in ["stop", "suspend"]) then
		{
			OO_FOREACHINSTANCE(MissionSpecialOperations,[],_stopRunningMissions);
		}
		else
		{
			private _specOpsMembers = [] call SPM_Mission_SpecOpsMembers;
			OO_FOREACHINSTANCE(MissionSpecialOperations,[_specOpsMembers],_stopAbandonedMissions);
		};

		OO_FOREACHINSTANCE(MissionSpecialOperations,[],_deleteStoppedMissions);

		sleep 5;
	};
};

