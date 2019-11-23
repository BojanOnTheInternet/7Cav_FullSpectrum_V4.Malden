player addEventHandler ["InventoryOpened",
	{
		params ["_unit", "_container"];

		[player] call GR_InventoryOpened;

		private _owner = objectParent _container;
		if (isPlayer _owner && _owner != _unit) then
		{
			[player] remoteExec ["GR_InventoryOpened", _owner];
			[[format ["%1 has opened your backpack", name player], "plain down", 0.3]] remoteExec ["titleText", _owner];
		};
	}];

player addEventHandler ["InventoryClosed",
	{
		params ["_unit", "_container"];

		[player] call GR_InventoryClosed;

		private _owner = objectParent _container;
		if (isPlayer _owner && _owner != _unit) then { [player] remoteExec ["GR_InventoryClosed", _owner] };
	}];

player addEventHandler ["Take",
	{
		params ["_unit", "_container", "_item"];

		// To handle taking directly from the ground (no InventoryOpened or InventoryClosed events)
		[player] call GR_InventoryOpened;
		[player] call GR_InventoryClosed;

		private _owner = objectParent _container;
		if (isPlayer _owner && _owner != _unit) then { [player, _item] remoteExec ["GR_InventoryTake", _owner] };
	}];

player addEventHandler ["Put",
	{
		params ["_unit", "_container", "_item"];

		private _owner = objectParent _container;
		if (isPlayer _owner && _owner != _unit) then { [player, _item] remoteExec ["GR_InventoryPut", _owner] };
	}];