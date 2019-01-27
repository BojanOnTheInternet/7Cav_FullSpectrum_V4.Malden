params [["_source", objNull, [objNull]], ["_blastPosition", [], [[]]], ["_blastDirection", [], [[]]], ["_knockDownVelocity", 5, [0]], ["_knockDownSweep", 90, [0]], ["_stunDuration", 5, [0]], ["_stunSweep", 180, [0]]];

if (count _blastPosition != 3) exitWith {};
if (count _blastDirection != 3) exitWith {};
if (_knockDownVelocity < 0) exitWith {};
if (_knockDownSweep < 0) exitWith {};
if (_stunDuration < 0) exitWith {};
if (_stunSweep < 0) exitWith {};

[_source, _blastPosition, _blastDirection, _knockDownVelocity, _knockDownSweep, _stunDuration, _stunSweep] call JB_CC_BlastArea