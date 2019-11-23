#include "\a3\editor_f\Data\Scripts\dikCodes.h"

waituntil {!isnull (finddisplay 46)};

(findDisplay 46) displayAddEventHandler ["KeyDown",
	{
		params ["_display", "_key", "_isShift", "_isCtrl", "_isAlt"];

		private _handled = false;

		if (_key == DIK_H) then
		{
			switch ([animationState player, "P"] call JB_fnc_getAnimationState) do
			{
				case "erc": { player playMoveNow "amovpercmstpsnonwnondnon" };
				case "knl": { player playMoveNow "amovpknlmstpsnonwnondnon" };
				case "pne": { player playMoveNow "amovppnemstpsnonwnondnon" };
			};

			player action ["SwitchWeapon", player, player, -1];
			PLAYER_WeaponGetIn = "";
			_handled = true;
		};

		_handled;
	}];
