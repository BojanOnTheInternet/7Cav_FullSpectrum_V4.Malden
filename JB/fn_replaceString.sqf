params ["_string", "_from", "_to"];

private _result = "";
private _index = 0;

while { _index = _string find _from; _index >= 0 } do
{
	_result = _result + (_string select [0, _index]) + _to;
	_string = _string select [_index + count _from];
};

_result + _string