params ["_radios"];

Radio_Custom_Radios = +_radios;

private _frequencies = []; // [[frequency, channel], ...]
{
	private _radio = _x;

	private _channel = 0;
	private _channels = (_radio select 3) apply
	{
		private _index = -1;
		for "_i" from 0 to count _frequencies - 1 do
		{
			if (_frequencies select _i select 0 == (_x select 1)) exitWith { _index = _i };
		};

		if (_index == -1) then
		{
			_channel = radioChannelCreate [_radio select 2, _x select 0, "", []];
			if (_channel != 0) then { _channel = _channel + 5 }; // Shift the channel into the normal channel number range
			_frequencies pushBack [_x select 1, _channel]; // Add the channel to the list of known frequencies so it can be reused
			_index = count _frequencies - 1;
		};

		_x + [_frequencies select _index select 1];
	};

	_x set [3, _channels];
} forEach Radio_Custom_Radios;

[[Radio_Custom_Radios], { Radio_Custom_Radios = (_this select 0) }] remoteExec ["call", 0, true];
