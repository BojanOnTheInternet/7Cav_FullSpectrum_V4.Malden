params [["_jogLimit", 35, [0]], ["_liftLimit", 1e30, [0]]];

player setVariable ["JB_CO_Player", [_jogLimit, _liftLimit]];

JB_CO_AddActions =
{
	private _actionPickUp = player addAction ["Pick up object", { [cursorObject] call JB_CO_PickUpAction }, nil, 10, true, true, "", "(player distance2D cursorObject <= 2) && { [cursorObject] call JB_CO_PickUpActionCondition }"];
	private _actionDrop = player addAction ["Drop object", { [] call JB_CO_DropAction }, nil, 10, true, true, "", "[] call JB_CO_DropActionCondition"];

	private _data = player getVariable "JB_CO_Player";
	_data set [2, _actionPickUp];
	_data set [3, _actionDrop];
};

call JB_CO_AddActions;
player addEventHandler ["Respawn", { call JB_CO_AddActions }];