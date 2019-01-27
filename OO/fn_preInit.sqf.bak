#include "oo.h"

//TODO: Consider typing references.  Instead of "#REF", make it ["#REF", 6] to indicate a reference to a specific type - or parent type.  Would need to add a way to disable the runtime type checks.

TRACE_INDENT = "";

OO_Classes = [];

OO_Root = OO_Classes pushBack ["Root", -1, [], [], [], -1];
OO_Root_IsClass = true;
OO_DEFINE_METHOD(Root,Create,{});
OO_DEFINE_METHOD(Root,Delete,{});
OO_DEFINE_PROPERTY(Root,Class,"SCALAR",-1);
OO_DEFINE_PROPERTY(Root,ID,"SCALAR",-1);

OO_RootStruct = OO_Classes pushBack ["RootStruct", -1, [], [], [], -1];
OO_RootStruct_IsClass = false;
OO_DEFINE_METHOD(RootStruct,Create,{});
OO_DEFINE_PROPERTY(RootStruct,Class,"SCALAR",-1);

OO_GET_INDIRECT =
{
	params ["_instance", "_propertyTable", "_propertyIndex"];

	private _propertyValue = _instance select _propertyIndex; 
	private _propertyType = _propertyTable select _propertyIndex select 0;

	if (OO_ISNULL(_propertyValue)) exitWith { OO_NULL };

	private _referencedIndex = _propertyValue select 0;
	private _referencedClass = _propertyValue select 1;

	private _referenceTable = OO_CLASSINDEX_REFERENCE_TABLE(_referencedClass);

	([_referenceTable, _referencedIndex] call REF_GetValue)
};

OO_SET_INDIRECT =
{
	params ["_instance", "_propertyTable", "_propertyIndex", "_propertyValue"];

	private _propertyType = _propertyTable select _propertyIndex select 0;

	if (typeName _propertyValue != "ARRAY") exitWith { diag_log format ["OO_SET_INDIRECT: Rejected attempt to set reference property to %1 value.  Property %4 in instance %3 of class '%2'", typeName _propertyValue, OO_CLASSINDEX_CLASS_NAME(OO_INSTANCE_CLASSINDEX(_instance)), OO_INSTANCE_ID(_instance), _propertyIndex] };

	if (count _propertyValue == 0) exitWith { _instance set [_propertyIndex, _propertyValue] };

	private _referencedIndex = OO_INSTANCE_ID(_propertyValue);
	private _referencedClass = OO_INSTANCE_CLASSINDEX(_propertyValue);

	_instance set [_propertyIndex, [_referencedIndex, _referencedClass]];
};

OO_FOREACHINSTANCE_BODY =
{
	params ["_classIndex", "_parameters", "_code"];

	private _stopOnInstance = [OO_CLASSINDEX_REFERENCE_TABLE(_classIndex), _parameters, _code] call REF_ForEachValue;

	if (not isNil "_stopOnInstance") exitWith { _stopOnInstance };

	private _subclasses = [];
	{
		if (OO_CLASS_PARENT_CLASSINDEX(_x) == _classIndex) then { _subclasses pushBack _forEachIndex };
	} forEach OO_Classes;

	{
		_stopOnInstance = [_x, _parameters, _code] call OO_FOREACHINSTANCE_BODY;
		if (not OO_ISNULL(_stopOnInstance)) exitWith {};
	} forEach _subclasses;

	if (isNil "_stopOnInstance") exitWith { OO_NULL };

	_stopOnInstance
};

OO_INSTANCE_ISOFCLASS_BODY =
{
	params ["_searchClassIndex", "_targetClassIndex"];

	while { _searchClassIndex != _targetClassIndex && _searchClassIndex != -1 } do
	{
		_searchClassIndex = OO_CLASSINDEX_PARENT_CLASSINDEX(_searchClassIndex);
	};

	_searchClassIndex != -1
};

OO_GetNamedProperties =
{
	params ["_object"];

	private _properties = [];

	private _propertyTable = OO_CLASSINDEX_PROPERTY_TABLE(OO_INSTANCE_CLASSINDEX(_object));

	private _value = "";
	{
		_value = _object select _forEachIndex;

		if (_forEachIndex == 0) then // _object class index
		{
			_value = OO_CLASSINDEX_CLASS_NAME(_value);
		}
		else
		{
			switch (_x select 0) do // property type
			{
				case "STRING": { };
				case "ARRAY":
				{
					if (typeName _value != typeName []) then
					{
						_value = format ["TYPE MISMATCH: %1", _value];
					}
					else
					{
						_value = format ["[%1] %2", count _value, _value];
						if (count _value > 60) then
						{
							_value = format ["%1...]", _value select [0, 60]];
						};
					};
				};
				case "CODE": { _value = "CODE" };
				case "#OBJ": { _value = if (OO_ISNULL(_value)) then { "OBJ: NULL" } else { format ["OBJ: %1 %2", OO_CLASSINDEX_CLASS_NAME(OO_INSTANCE_CLASSINDEX(_value)), OO_INSTANCE_ID(_value)] } };
				case "#REF":
				{
					private _referenced = [_object, _propertyTable, _forEachIndex] call OO_GET_INDIRECT;
					_value = if (OO_ISNULL(_referenced)) then { "REF: NULL" } else { format ["REF: %1 %2", OO_CLASSINDEX_CLASS_NAME(OO_INSTANCE_CLASSINDEX(_referenced)), OO_INSTANCE_ID(_referenced)] };
				};
				default { _value = str _value };
			};
		};
		_properties pushBack [_x select 2, _value]; // name

	} forEach _propertyTable;

	_properties
};