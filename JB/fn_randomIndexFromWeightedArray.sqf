/*
	index = [weightedValues] call JB_fnc_randomItemFromWeightedArray;

	weightedValues - an array of value pairs, a value and a weight

	index - the index of the random value taken from the weightedValues array
*/

private _weightedValues = param[0, [], [[]]];

private _totalWeight = 0;
{
	_totalWeight = _totalWeight + (_x select 0);
} foreach _weightedValues;

private _randomWeight = floor(random _totalWeight);

private _value = 0;

private _currentWeight = 0;
{
	_value = _forEachIndex;
	_currentWeight = _currentWeight + (_x select 0);
	if (_randomWeight < _currentWeight) exitWith {};
} foreach _weightedValues;

_value;