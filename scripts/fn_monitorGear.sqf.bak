params ["_restrictions"];

private _player = player;

private _violations = [];
while { alive _player } do
{
	{
		_violations = _violations + (call _x);
	} foreach (_restrictions + [{ call GR_ProhibitedItemsRestriction }]);

	if (count _violations > 0) then
	{
		private _message = _violations joinString "\n";

		titleText [_message, "BLACK"];
		sleep (2 + (count _violations) * 0.5);
		titleFadeOut 1;

		_violations = [];
	};

	[{ call GR_IsChangingInventory }, 30, 1] call JB_fnc_timeoutWaitUntil;
};