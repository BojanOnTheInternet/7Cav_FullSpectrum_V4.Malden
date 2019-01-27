params ["_faction"];

_factions =
[
	["BLU_F", "NATO", west],
	["BLU_T_F", "NATO", west],
	["BLU_CTRG_F", "CTRG", west],
	["BLU_GEN_F", "Gendarmerie", west],
	["BLU_G_F", "FIA", west],
	["OPF_G_F", "FIA", east],
	["IND_G_F", "FIA", independent],
	["OPF_F", "CSAT", east],
	["OPF_T_F", "CSAT", east],
	["IND_F", "AAF", independent],
	["IND_C_F", "Syndikat", independent],
	["CIV_F", "Civilian", civilian]
];

private _index = _factions find { (_x select 0) == _faction };

if (_index == -1) exitWith { [] };

_factions select _index select [1, 1e3]