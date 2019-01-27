// Don't let player open locked containers
player addEventHandler ["InventoryOpened",
	{
		private _override = false;

		if ((_this select 1) getVariable ["JBC_Locked", false]) then
		{
			player action ["Gear", objNull];
			_override = true;
		};

		_override
	}];