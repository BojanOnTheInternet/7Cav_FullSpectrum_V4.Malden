private _class = param [0, "", [""]];
private _parentClass = param [1, "", [""]];

private _displayName = "";

if (_parentClass != "") then
{
	_displayName = getText (configFile >> _parentClass >> _class >> "displayName");
}
else
{
	_displayName = getText (configFile >> "CfgVehicles" >> _class >> "displayName");

	if (_displayName == "") then
	{
		_displayName = getText (configFile >> "CfgWeapons" >> _class >> "displayName");
	};
	if (_displayName == "") then
	{
		_displayName = getText (configFile >> "CfgMagazines" >> _class >> "displayName");
	};
	if (_displayName == "") then
	{
		_displayName = getText (configFile >> "CfgAmmo" >> _class >> "displayName");
	};
};

_displayName;