JB_SR_PlaySearchRubbleAnimations =
{
	player playMove "AmovPknlMstpSnonWnonDnon";
};

JB_SR_IsBuildingWithRubble =
{
	params ["_object"];

	if (not (_object isKindOf "HouseBase")) exitWith { false };

	private _type = toLower typeOf _object;
	if (_type find "_dam_f" == -1 && _type find "ruins_f" == -1) exitWith { false }; 

	true
};

JB_SR_SearchRubbleCondition =
{
	if (vehicle player != player) exitWith { false };

	if (not (lifeState player in ["HEALTHY", "INJURED"])) exitWith { false };

	if ([animationState player, ["cin", "inv"]] call JB_fnc_matchAnimationState) exitWith { false };

	if ((getPosATL player) select 2 < 0.1) exitWith { false }; // A simple check to suggest they're in a building

	private _standingOn = lineIntersectsObjs [eyePos player, ATLToASL getpos player, player, objNull, true, 16];
	if (count _standingOn == 0) exitWith { false };

	if (not ([_standingOn select 0] call JB_SR_IsBuildingWithRubble))	exitWith { false };

	true
};

JB_SR_SearchRubbleInterrupted =
{
	params ["_entryAnimation"];

	player playMoveNow _entryAnimation;
};

JB_SR_SearchRubbleCompleted =
{
	params ["_entryAnimation"];

	[_entryAnimation] call JB_SR_SearchRubbleInterrupted;

	private _extractionCallback = player getVariable ["JB_SR_ExtractionCallback", [{ (_this select 0) setPosASL (_this select 1); true }, 0]];

	private _objects = (getpos player nearobjects ["All", 4.0]) select { not (_x isKindOf "Building") && _x != player };

	private _foundObject = false;

	while { not _foundObject && count _objects > 0 } do
	{
		private _object = _objects deleteAt (floor random count _objects);
		private _intersections = lineIntersectsSurfaces [(getPosASL _object) vectorAdd [0,0,2], getPosASL _object, player, objNull, true, 1, "VIEW", ""];

		if (count _intersections == 1 && { [_intersections select 0 select 3] call JB_SR_IsBuildingWithRubble }) then
		{
			if ([_object, ((_intersections select 0 select 0) vectorAdd [0,0,0.5]), if (isNil { _extractionCallback select 1 }) then { nil } else { _extractionCallback select 1 }] call (_extractionCallback select 0)) then
			{
				_foundObject = true;

				if (not (_object isKindOf "Man") || { side _object getFriend side player < 0.6 }) then
				{
					titleText [format ["You have pulled a %1 from the rubble", getText (configFile >> "CfgVehicles" >> typeOf _object >> "displayName")], "plain down", 0.3];
				}
				else
				{
					titleText [format ["You have pulled %1 from the rubble", name _object], "plain down", 0.3];
					if (isPlayer _object) then { [format ["%1 has pulled you from the rubble", name player], "plain down", 0.3] remoteExec ["titleText", _object] };
				};
			};
		};
	};
};

JB_SR_SearchRubbleHoldActionInterval =
{
	params ["_elapsedTime", "_progress", "_passthrough"];

	if (([JB_HA_STATE] call JB_fnc_holdActionGetValue) == "keyup") exitWith
	{
		[_passthrough select 0] call JB_SR_SearchRubbleInterrupted;
	};

	switch (true) do
	{
		case (_progress == 0.0):
		{
			[] call JB_SR_PlaySearchRubbleAnimations;
		};

		case (_progress == 1.0):
		{
			[] call JB_fnc_holdActionStop;
			[_passthrough select 0] call JB_SR_SearchRubbleCompleted;
		};
	};
};

JB_SR_SearchRubbleHoldAction =
{
	params ["_target", "_caller", "_id"];

	[actionKeys "action", 3.0, 1.0, JB_SR_SearchRubbleHoldActionInterval, [animationState player]] call JB_fnc_holdActionStart;
	[JB_HA_LABEL, str parseText ((player actionParams _id) select 0)] call JB_fnc_holdActionSetValue;
	[JB_HA_FOREGROUND_ICON, "\a3\ui_f\data\IGUI\Cfg\HoldActions\holdAction_search_ca.paa"] call JB_fnc_holdActionSetValue;
};