/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer && hasInterface) exitWith {};

#include "strongpoint.h"

SPM_Transport_RemoveWeapons =
{
	private _vehicle = _this select 0;
	{
		_vehicle removeWeapon _x;
	} foreach weapons _vehicle;

	{
		_vehicle removeMagazines _x;
	} forEach magazines _vehicle;
};

OO_TRACE_DECL(SPM_TransportRequest_DetachVehicle) =
{
	params ["_request"];

	private _forceUnit = OO_GET(_request,TransportRequest,ForceUnit);
	if (count _forceUnit > 0) then
	{
		OO_SET(_forceUnit,ForceUnit,Vehicle,objNull);
	};
};

OO_TRACE_DECL(SPM_TransportRequest_Command) =
{
	params ["_request", "_command", "_parameters"];

	switch (_command) do
	{
		case "surrender":
		{
			[_request] call OO_GET(_request,TransportRequest,OnSurrender);

			private _forceUnit = OO_GET(_request,TransportRequest,ForceUnit);
			if (count _forceUnit > 0) then
			{
				[OO_GET(_forceUnit,ForceUnit,Vehicle)] call SPM_Util_SurrenderVehicle;
				{ [_x] call SPM_Util_SurrenderMan } forEach crew OO_GET(_forceUnit,ForceUnit,Vehicle); // To get any dismounted crewmen
			};
		};

		case "minimize":
		{
			private _forceUnit = OO_GET(_request,TransportRequest,ForceUnit);
			if (count _forceUnit > 0) then
			{
				[_forceUnit] call SPM_Force_DeleteForceUnit;
			};
		};
	};
};

OO_TRACE_DECL(SPM_TransportRequest_Create) =
{
	params ["_request", "_passengers", "_destination"];

	OO_SET(_request,TransportRequest,Passengers,_passengers);
	OO_SET(_request,TransportRequest,Destination,_destination);
};

OO_TRACE_DECL(SPM_TransportRequest_Delete) =
{
	params ["_request"];

	[_request] call OO_GET(_request,TransportRequest,OnSalvage);

	private _forceUnit = OO_GET(_request,TransportRequest,ForceUnit);
	if (count _forceUnit > 0) then
	{
		[_forceUnit] call SPM_Force_DeleteForceUnit;
	};
};

OO_BEGIN_CLASS(TransportRequest);
	OO_OVERRIDE_METHOD(TransportRequest,Root,Create,SPM_TransportRequest_Create);
	OO_OVERRIDE_METHOD(TransportRequest,Root,Delete,SPM_TransportRequest_Delete);
	OO_DEFINE_METHOD(TransportRequest,Update,{});
	OO_DEFINE_METHOD(TransportRequest,DetachVehicle,SPM_TransportRequest_DetachVehicle);
	OO_DEFINE_METHOD(TransportRequest,Command,SPM_TransportRequest_Command);
	OO_DEFINE_PROPERTY(TransportRequest,VehicleCallup,"ARRAY",[]);
	OO_DEFINE_PROPERTY(TransportRequest,Operation,"#REF",OO_NULL);
	OO_DEFINE_PROPERTY(TransportRequest,Passengers,"SCALAR",0);
	OO_DEFINE_PROPERTY(TransportRequest,Destination,"ARRAY",[]);
	OO_DEFINE_PROPERTY(TransportRequest,ForceUnit,"ARRAY",[]);
	OO_DEFINE_PROPERTY(TransportRequest,Ratings,"ARRAY",[]);
	OO_DEFINE_PROPERTY(TransportRequest,State,"STRING","create"); // create, pending, to-destination, to-cover, stopped, retire, complete
	OO_DEFINE_PROPERTY(TransportRequest,ClientData,"ARRAY",[]);
	OO_DEFINE_PROPERTY(TransportRequest,OnLoad,"CODE",{true});
	OO_DEFINE_PROPERTY(TransportRequest,OnUpdate,"CODE",{});
	OO_DEFINE_PROPERTY(TransportRequest,OnArrive,"CODE",{});
	OO_DEFINE_PROPERTY(TransportRequest,OnSalvage,"CODE",{});
	OO_DEFINE_PROPERTY(TransportRequest,OnSurrender,"CODE",{});
OO_END_CLASS(TransportRequest);

OO_TRACE_DECL(SPM_TransportOperation_Update) =
{
	params ["_operation", "_category"];

	private _requests = OO_GET(_operation,TransportOperation,Requests);

	for "_i" from (count _requests - 1) to 0 step -1 do
	{
		private _request = _requests select _i;
		if (OO_GET(_request,TransportRequest,State) == "complete") then { _request = _requests deleteAt _i; call OO_DELETE(_request) };
	};

	{
		[_category, _operation] call OO_METHOD(_x,TransportRequest,Update);
	} forEach _requests;
};

OO_TRACE_DECL(SPM_TransportOperation_AddRequest) =
{
	params ["_operation", "_request", "_index"];

	OO_SETREF(_request,TransportRequest,Operation,_operation);

	private _requests = OO_GET(_operation,TransportOperation,Requests);

	if (isNil "_index") then
	{
		_requests pushBack _request;
	}
	else
	{
		_requests = (_requests select [0, _index]) + [_request] + (_requests select [_index, 1e3]);
		OO_SET(_operation,TransportOperation,Requests,_requests);
	};
};

OO_TRACE_DECL(SPM_TransportOperation_Command) =
{
	params ["_operation", "_command", "_parameters"];

	{
		[_command, _parameters] call OO_METHOD(_x,TransportRequest,Command);
	} forEach OO_GET(_operation,TransportOperation,Requests);
};

OO_TRACE_DECL(SPM_TransportOperation_Create) =
{
	params ["_operation", "_area", "_spawnpoint"];

	OO_SET(_operation,TransportOperation,Area,_area);
	OO_SET(_operation,TransportOperation,Spawnpoint,_spawnpoint);
};

OO_TRACE_DECL(SPM_TransportOperation_Delete) =
{
	params ["_operation"];

	private _requests = OO_GET(_operation,TransportOperation,Requests);
	while { count _requests > 0 } do
	{
		private _request = _requests select 0;
		[] call OO_METHOD(_request,Root,Delete);
		_requests deleteAt 0;
	};
};

OO_BEGIN_CLASS(TransportOperation);
	OO_OVERRIDE_METHOD(TransportOperation,Root,Create,SPM_TransportOperation_Create);
	OO_OVERRIDE_METHOD(TransportOperation,Root,Delete,SPM_TransportOperation_Delete);
	OO_DEFINE_METHOD(TransportOperation,AddRequest,SPM_TransportOperation_AddRequest);
	OO_DEFINE_METHOD(TransportOperation,Update,SPM_TransportOperation_Update);
	OO_DEFINE_METHOD(TransportOperation,Command,SPM_TransportOperation_Command);
	OO_DEFINE_PROPERTY(TransportOperation,Category,"#REF",OO_NULL);
	OO_DEFINE_PROPERTY(TransportOperation,Area,"ARRAY",[]); // StrongpointArea structure
	OO_DEFINE_PROPERTY(TransportOperation,Spawnpoint,"ARRAY",[]);
	OO_DEFINE_PROPERTY(TransportOperation,Requests,"ARRAY",[]);
	OO_DEFINE_PROPERTY(TransportOperation,VehicleCallups,"ARRAY",[]);
OO_END_CLASS(TransportOperation);

OO_TRACE_DECL(SPM_Transport_Update) =
{
	params ["_category"];

	[] call OO_METHOD_PARENT(_category,Category,Update,ForceCategory);

	if (OO_GET(_category,ForceCategory,_Surrendered)) exitWith {};

	private _operations = OO_GET(_category,TransportCategory,Operations);

	for "_i" from (count _operations - 1) to 0 step -1 do
	{
		private _operation = _operations select _i;
		if (count OO_GET(_operation,TransportOperation,Requests) == 0) then { _operation = _operations deleteAt _i; call OO_DELETE(_operation) };
	};

	{
		[_category] call OO_METHOD(_x,TransportOperation,Update);
	} forEach _operations;
};

OO_TRACE_DECL(SPM_Transport_AddOperation) =
{
	params ["_category", "_operation"];

	OO_SETREF(_operation,TransportOperation,Category,_category);

	private _operations = OO_GET(_category,TransportCategory,Operations);
	_operations pushBack _operation;
};

OO_TRACE_DECL(SPM_Transport_Command) =
{
	params ["_category", "_command", "_parameters"];

	switch (_command) do
	{
		case "surrender":
		{
			if (OO_GET(_category,ForceCategory,_Surrendered)) exitWith {};
			
			OO_SET(_category,ForceCategory,_Surrendered,true);
			{
				["surrender", _parameters] call OO_METHOD(_x,TransportOperation,Command);
			} forEach OO_GET(_category,TransportCategory,Operations);
		};

		default
		{
			{
				[_command, _parameters] call OO_METHOD(_x,TransportOperation,Command);
			} forEach OO_GET(_category,TransportCategory,Operations);
		};
	};
};

OO_TRACE_DECL(SPM_Transport_Create) =
{
	params ["_category"];

	OO_SET(_category,Category,GetUpdateInterval,{2});
};

OO_TRACE_DECL(SPM_Transport_Delete) =
{
	params ["_category"];

	// Delete operations
	private _operations = OO_GET(_category,TransportCategory,Operations);
	while { count _operations > 0 } do
	{
		private _operation = _operations select 0;
		[] call OO_METHOD(_operation,Root,Delete);
		_operations deleteAt 0;
	};

	// Remove from any garrisons using it //TODO: Add events so we avoid a priori knowledge of other classes
	private _strongpoint = OO_GETREF(_category,Category,Strongpoint);
	{
		if (OO_GET(_x,InfantryGarrisonCategory,Transport) isEqualTo _category) then { OO_GET(_x,InfantryGarrisonCategory,Transport,OO_NULL) };
	} forEach (OO_GET(_strongpoint,Strongpoint,Categories) select { OO_INSTANCE_ISOFCLASS(_x,InfantryGarrisonCategory) });
};

OO_BEGIN_SUBCLASS(TransportCategory,ForceCategory);
	OO_OVERRIDE_METHOD(TransportCategory,Root,Create,SPM_Transport_Create);
	OO_OVERRIDE_METHOD(TransportCategory,Root,Delete,SPM_Transport_Delete);
	OO_OVERRIDE_METHOD(TransportCategory,Category,Update,SPM_Transport_Update);
	OO_OVERRIDE_METHOD(TransportCategory,Category,Command,SPM_Transport_Command);
	OO_DEFINE_METHOD(TransportCategory,AddOperation,SPM_Transport_AddOperation);
	OO_DEFINE_PROPERTY(TransportCategory,SideEast,"SIDE",east);
	OO_DEFINE_PROPERTY(TransportCategory,SideWest,"SIDE",west);
	OO_DEFINE_PROPERTY(TransportCategory,Operations,"ARRAY",[]);
	OO_DEFINE_PROPERTY(TransportCategory,SeaTransports,"ARRAY",SPM_Transport_CallupsEastSpeedboat);
	OO_DEFINE_PROPERTY(TransportCategory,GroundTransports,"ARRAY",SPM_Transport_CallupsEastMarid);
	OO_DEFINE_PROPERTY(TransportCategory,AirTransports,"ARRAY",SPM_Transport_CallupsEastMohawk);
OO_END_SUBCLASS(TransportCategory);