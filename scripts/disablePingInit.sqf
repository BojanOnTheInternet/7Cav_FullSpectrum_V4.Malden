waituntil { not isNull (findDisplay 46) };
	
(findDisplay 46) displayAddEventHandler ["KeyDown",
	{
		params ["_display", "_key", "_isShift", "_isCtrl", "_isAlt"];

		private _override = false;

		if (isNull getAssignedCuratorLogic player && { (inputAction "curatorinterface") > 0 }) then
		{
			["Zeus pinging is disabled.  Use chat to contact any available mission controllers or military police.", 1] call JB_fnc_showBlackScreenMessage;
			_override = true;
		};

		_override
	}];
