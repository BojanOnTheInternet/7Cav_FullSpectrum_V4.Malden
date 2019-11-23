HealOther_PlayAnimations =
{
	private _animation = "AinvPpneMstpSlayWnonDnon_medicOther";

	if (stance player in ["STAND", "CROUCH"]) then { _animation = [_animation, "p", "knl"] call JB_fnc_setAnimationState };

	if (primaryWeapon player != "" && currentWeapon player == primaryWeapon player) then { _animation = [_animation, "w", "rfl"] call JB_fnc_setAnimationState };
	if (handgunWeapon player != "" && currentWeapon player == handgunWeapon player) then { _animation = [_animation, "w", "pst"] call JB_fnc_setAnimationState };

	player playMove _animation;
};

HealOther_Interrupted =
{
	params ["_entryAnimation"];

	// The heal animations don't break out on a playMoveNow
	if (animationState player find "_medic" >= 0) then { player switchMove format ["AmovP%1MstpSnonWnonDnon", [animationState player, "p"] call JB_fnc_getAnimationState] };

	player playMoveNow _entryAnimation;
};

HealOther_Completed =
{
	params ["_wounded", "_entryAnimation"];

	[_entryAnimation] call HealOther_Interrupted;

	if (player getUnitTrait "medic" && "Medikit" in backpackItems player)  then
	{
		[_wounded, 1.0] call JBM_Heal;
	}
	else
	{
		[player] call JBM_ConsumeFirstAidKit;
		[_wounded, if (player getUnitTrait "medic") then { 1.0 } else { 0.75 }] call JBM_Heal;
	};
};

HealOther_ShouldContinue =
{
	params ["_wounded"];

	if (vehicle _wounded != _wounded) exitWith { false };

	if (not (lifeState player in ["HEALTHY", "INJURED"])) exitWith { false };

	if (player distance _wounded > 3) exitWith { false };

	private _injuryLevel = if (player getUnitTrait "medic") then { 0.0 } else { 0.25 };
	if ({ _x > _injuryLevel } count (getAllHitPointsDamage _wounded select 2) == 0) exitWith { false };

	true
};

HealOther_HoldActionInterval =
{
	params ["_elapsedTime", "_progress", "_passthrough"];

	// If a criterion for the heal fails or the player releases the key, interrupt the process
	if (not ([_passthrough select 2] call HealOther_ShouldContinue) || { ([JB_HA_STATE] call JB_fnc_holdActionGetValue) == "keyup" }) exitWith
	{
		[] call JB_fnc_holdActionStop;
		[_passthrough select 0] call HealOther_Interrupted;
	};

	// If we've started and finished a medic animation, we're done
	if ((_passThrough select 1) && ([animationState player, "a"] call JB_fnc_getAnimationState) == "mov") exitWith
	{
		[] call JB_fnc_holdActionStop;
		[_passThrough select 2, _passthrough select 0] call HealOther_Completed;
	};

	// Note when we've started a medic animation.  When the animation completes, we're done
	if (animationState player find "_medic" > 0) then
	{
		_passthrough set [1, true];
	};

	switch (true) do
	{
		case (_progress == 0.0):
		{
			[[format ["%1 is healing you", name player], "plain down", 0.5]] remoteExec ["titleText", _passthrough select 2];
			[] call HealOther_PlayAnimations;
		};

		// We shouldn't get here, but just in case...
		case (_progress == 1.0):
		{
			[] call JB_fnc_holdActionStop;
			[_passthrough select 2, _passthrough select 0] call HealOther_Completed;
		};
	};
};

HealOther_HoldAction =
{
	params ["_target", "_caller", "_index", "_name", "_text"];

	[actionKeys "Action", 13.0, 1.0, HealOther_HoldActionInterval, [animationState player, false, _target]] call JB_fnc_holdActionStart;
	[JB_HA_LABEL, _text] call JB_fnc_holdActionSetValue;
	[JB_HA_FOREGROUND_ICON, "\a3\ui_f\data\IGUI\Cfg\HoldActions\holdAction_revive_ca.paa"] call JB_fnc_holdActionSetValue;

	// format [localize "str_a3_cfgactions_healsoldier0", getText (configFile >> "CfgVehicles" >> typeOf cursorObject >> "displayName")]
	// "str_a3_cfgactions_healsoldierauto0" - Treat soldier

	true
};

HealOther_HoldKey =
{
	systemchat "Not implemented"; //TODO:
};

["HealSoldier", HealOther_HoldAction, HealOther_HoldKey, HealOther_HoldKey] call CLIENT_OverrideAction;
