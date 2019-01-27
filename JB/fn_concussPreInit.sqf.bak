JB_CC_StunUnit =
{
	_this spawn
	{
		params ["_unit", "_scale"];

		if (isPlayer _unit) then
		{
			["JB_CC_Stun", 0.0, 0.0] call JB_fnc_hearingSetLevel;
			sleep 0.2 * _scale;
			["JB_CC_Stun", 1.0, 0.8 * _scale] call JB_fnc_hearingSetLevel;
		};
	};
};

JB_CC_KnockDownUnit =
{
	_this spawn
	{
		params ["_unit", "_velocity", "_duration"];

		_unit setVelocity ((velocity _unit) vectorAdd _velocity);

		if (lifeState _unit == "INCAPACITATED") exitWith {};

		if (_unit == player) then { ["JB_CC_KnockDown", 0.3, 0.0] call JB_fnc_hearingSetLevel };

		sleep 0.1; // Let velocity change take hold
		_unit setUnconscious true;
		waitUntil { animationState _unit == "unconsciousrevivedefault" };
		if (_unit == player && _duration > 2) then { titleText [format ["You have been knocked down for %1 seconds", round _duration], "plain down", 0.3] };
		sleep _duration;
		_unit setUnconscious false;
		if (_unit == player) then { ["JB_CC_KnockDown", 1.0, 5] call JB_fnc_hearingSetLevel };
		_unit playMoveNow "AmovPpneMstpSnonWnonDnon";
	};
};

JB_CC_BlastArea =
{
	params ["_source", "_blastPosition", "_blastDirection", "_knockDownVelocity", "_knockDownSweep", "_stunDuration", "_stunSweep"];

	private _blastPositionASL = AGLtoASL _blastPosition;

	private _minKnockDown = 1; // Velocity imparted at one meter
	private _minKnockDownCosine = cos (_knockDownSweep / 2.0);
	private _maxKnockDown = _knockDownVelocity; // Velocity imparted at one meter
	private _maxKnockDownCosine = cos 0;

	private _minKnockDownEffect = 0.1;
	private _maxKnockDownDistance = sqrt (_maxKnockDown / _minKnockDownEffect);

	private _minStun = 1; // Time of stuning imparted at one meter
	private _minStunCosine = cos (_stunSweep / 2.0);
	private _maxStun = _stunDuration; // Time of stuning imparted at one meter
	private _maxStunCosine = _minKnockDownCosine;

	private _minStunEffect = 0.5;
	private _maxStunDistance = sqrt (_maxStun / _minStunEffect);

	{
		private _bodyPositionASL = getPosASL _x vectorAdd (_x selectionPosition "spine2");
		private _bodyDirection = _blastPositionASL vectorFromTo _bodyPositionASL;
		private _cosine = _blastDirection vectorDotProduct _bodyDirection;

		private _intersections = lineIntersectsObjs [_blastPositionASL, _bodyPositionASL, _source, _x, false, 32 + 16];

		private _knockedDown = false;
		if (_cosine >= _minKnockDownCosine) then
		{
			private _effect = linearConversion [_minKnockDownCosine, _maxKnockDownCosine, _cosine, _minKnockDown, _maxKnockDown];

			private _distance = _blastPositionASL distance _bodyPositionASL;
			_distance = (_distance * _distance) max 0.5;
			_effect = _effect / _distance / (count _intersections * 1.0 + 1.0);
			if (_effect > _minKnockDownEffect) then
			{
				[_x, _blastDirection vectorMultiply _effect, _effect] remoteExec ["JB_fnc_concussKnockDownUnit", _x];
				_knockedDown = true;
			};
		};

		if (not _knockedDown && _cosine >= _minStunCosine) then
		{
			private _effect = linearConversion [_minStunCosine, _maxStunCosine, _cosine, _minStun, _maxStun];

			private _distance = _blastPositionASL distance _bodyPositionASL;
			_distance = (_distance * _distance) max 0.5;
			_effect = _effect / _distance / (count _intersections * 0.3 + 1.0);

			[_x, _effect] remoteExec ["JB_CC_StunUnit", _x];
		};
	} forEach (_blastPosition nearObjects ["Man", _maxKnockDownDistance max _maxStunDistance]);
};