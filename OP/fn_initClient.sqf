#include "op.h"

player setVariable ["OP_Selection", OP_SELECTION_NULL, true];

[] spawn
{
	scriptName "OP_fnc_initClient";

	while { true } do
	{
		waitUntil { sleep 1; not isNull (findDisplay 312) };
		[] call OP_InstallHandlers;
		waitUntil { sleep 1; isNull (findDisplay 312) };
	};
};
