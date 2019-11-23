waitUntil { not isNull (findDisplay 46) };

(findDisplay 46) displayAddEventHandler ["KeyDown",
	{
		params ["_display", "_key", "_isShift", "_isCtrl", "_isAlt"];

		private _override = false;

		if (vehicle player == player && _key in actionKeys "GetOver") then
		{
			private _animationState = animationState player;
			if (count _animationState > 16 && { [_animationState, "mov", "erc", ["tac", "run", "eva", "spr"], ["ras", "low"]] call JB_fnc_matchAnimationState }) then
			{
				[player, "AovrPercMrunSrasWrflDf"] remoteExec ["switchMove", 0];
				_override = true;
			}
			else
			{
				//TODO: This doesn't work because the falling character's velocity is 10m/s.  We can't look for that because a truly falling character shouldn't be able to trigger this.  So the code needs to know that the character isn't actually moving downwards.
				if (count _animationState > 16 && { [_animationState, "fal"] call JB_fnc_matchAnimationState } && { vectorMagnitude (velocity player) < 1 }) then
				{
					player setVelocity (player vectorModelToWorld [0, 3, 3]);
				};
			};
		};

		_override
	}];
