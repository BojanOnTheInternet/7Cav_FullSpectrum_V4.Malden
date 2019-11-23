//#define OO_TRACE
// Must define OO_CHECK and OO_TRACE_GET to get a trace on OO_GETs
//#define OO_TRACE_GET
//#define OO_CHECK

#define OO_NULL [-1,-1]
#define OO_ISEQUAL(instance1,instance2) (OO_INSTANCE_ID(instance1)==OO_INSTANCE_ID(instance2) && OO_INSTANCE_CLASSINDEX(instance1)==OO_INSTANCE_CLASSINDEX(instance2))
#define OO_ISNULL(instance) OO_ISEQUAL(instance,OO_NULL)

#define OO_ISCLASS(name) (OO_##name##_IsClass)

#define OO_INSTANCE_ISOFCLASS(instance,class)\
([OO_INSTANCE_CLASSINDEX(instance), OO_##class] call OO_INSTANCE_ISOFCLASS_BODY)

#define OO_INSTANCE_CLASSINDEX(instance) ((instance) select 0)
#define OO_INSTANCE_CLASS(instance) OO_CLASSINDEX_CLASS(OO_INSTANCE_CLASSINDEX(instance))
#define OO_INSTANCE_ID(instance) ((instance) select 1)
#define OO_INSTANCE_REFERENCE_TABLE(instance) OO_CLASSINDEX_REFERENCE_TABLE(OO_INSTANCE_CLASSINDEX(instance))

#define OO_CLASSNAME_CLASS(class) (OO_Classes select OO_##class)
#define OO_CLASSINDEX_CLASS(class) (OO_Classes select (class))

#define OO_CLASS_NAME(class) ((class) select 0)
#define OO_CLASS_PARENT_CLASSINDEX(class) ((class) select 1)
#define OO_CLASS_METHOD_TABLE(class) ((class) select 2)
#define OO_CLASS_PROPERTY_TABLE(class) ((class) select 3)
#define OO_CLASS_REFERENCE_TABLE(class) ((class) select 4)

#define OO_CLASSNAME_CLASS_NAME(class) (OO_CLASSNAME_CLASS(class) select 0)
#define OO_CLASSNAME_PARENT_CLASSINDEX(class) (OO_CLASSNAME_CLASS(class) select 1)
#define OO_CLASSNAME_METHOD_TABLE(class) (OO_CLASSNAME_CLASS(class) select 2)
#define OO_CLASSNAME_PROPERTY_TABLE(class) (OO_CLASSNAME_CLASS(class) select 3)
#define OO_CLASSNAME_REFERENCE_TABLE(class) (OO_CLASSNAME_CLASS(class) select 4)

#define OO_CLASSINDEX_CLASS_NAME(class) (OO_CLASSINDEX_CLASS(class) select 0)
#define OO_CLASSINDEX_PARENT_CLASSINDEX(class) (OO_CLASSINDEX_CLASS(class) select 1)
#define OO_CLASSINDEX_METHOD_TABLE(class) (OO_CLASSINDEX_CLASS(class) select 2)
#define OO_CLASSINDEX_PROPERTY_TABLE(class) (OO_CLASSINDEX_CLASS(class) select 3)
#define OO_CLASSINDEX_REFERENCE_TABLE(class) (OO_CLASSINDEX_CLASS(class) select 4)


#ifdef OO_CHECK
#define OO_OVERRIDE_METHOD_CHECK(class,parent,method,code)\
if (isNil { OO_##class }) then { diag_log "OO_OVERRIDE_METHOD: ERROR: undefined class" };\
if (isNil { OO_##parent }) then { diag_log "OO_OVERRIDE_METHOD: ERROR: undefined parent" };\
if (isNil { OO_##parent##_Method_##method }) then { diag_log "OO_OVERRIDE_METHOD: ERROR: undefined parent method" };\
if (isNil { code }) then { diag_log "OO_OVERRIDE_METHOD: ERROR: undefined code" }
#else
#define OO_OVERRIDE_METHOD_CHECK(class,parent,method,code)
#endif

#define OO_OVERRIDE_METHOD(class,parent,method,code)\
OO_OVERRIDE_METHOD_CHECK(class,parent,method,code);\
OO_CLASSNAME_METHOD_TABLE(class) set [OO_##parent##_Method_##method,(code)]


#ifdef OO_CHECK
#define OO_DEFINE_METHOD_CHECK(class,method,code)\
if (isNil{ OO_##class }) then{ diag_log "OO_DEFINE_METHOD: ERROR: undefined class" }; \
if (isNil { code }) then { diag_log "OO_DEFINE_METHOD: ERROR: undefined code" }
#else
#define OO_DEFINE_METHOD_CHECK(class,method,code)
#endif

#define OO_DEFINE_METHOD(class,method,code)\
OO_DEFINE_METHOD_CHECK(class,method,code);\
OO_##class##_Method_##method = count OO_CLASSNAME_METHOD_TABLE(class);\
OO_CLASSNAME_METHOD_TABLE(class) pushBack code


#ifdef OO_CHECK
#define OO_DEFINE_PROPERTY_CHECK(class,property,type,default)\
if (isNil { OO_##class }) then { diag_log "OO_DEFINE_PROPERTY: ERROR: undefined class" };\
if (isNil { type }) then { diag_log "OO_DEFINE_PROPERTY: ERROR: undefined type" }
#else
#define OO_DEFINE_PROPERTY_CHECK(class,property,type,default)
#endif

#define OO_DEFINE_PROPERTY(class,property,type,default)\
OO_DEFINE_PROPERTY_CHECK(class,property,type,default);\
OO_##class##_Property_##property = count OO_CLASSNAME_PROPERTY_TABLE(class);\
OO_CLASSNAME_PROPERTY_TABLE(class) pushBack [(type),(default),#property]


#ifdef OO_CHECK
#define OO_BEGIN_SUBCLASS_CHECK(class,parent)\
if (isNil { OO_##parent }) then { diag_log "OO_BEGIN_SUBCLASS: ERROR: undefined parent" }
#else
#define OO_BEGIN_SUBCLASS_CHECK(class,parent)
#endif

#ifdef OO_TRACE
#define OO_BEGIN_SUBCLASS_TRACE(class,parent)\
diag_log format ["BEGIN_SUBCLASS %1 %2", #class, #parent]
#else
#define OO_BEGIN_SUBCLASS_TRACE(class,parent)
#endif

#define OO_BEGIN_SUBCLASS(class,parent)\
OO_BEGIN_SUBCLASS_CHECK(class,parent);\
OO_BEGIN_SUBCLASS_TRACE(class,parent);\
OO_##class##_IsClass = OO_ISCLASS(parent);\
OO_##class = OO_Classes pushback [#class, OO_##parent, +OO_CLASSNAME_METHOD_TABLE(parent), +OO_CLASSNAME_PROPERTY_TABLE(parent), if (not OO_##class##_IsClass) then { -1 } else { [#class, 1] call REF_CreateTable }]


#ifdef OO_CHECK
#define OO_END_SUBCLASS_CHECK(class)\
if (isNil { OO_##class }) then { diag_log "OO_END_SUBCLASS: ERROR: undefined class" }
#else
#define OO_END_SUBCLASS_CHECK(class)
#endif

#ifdef OO_TRACE
#define OO_END_SUBCLASS_TRACE(class)\
diag_log format["END_SUBCLASS %1", #class]
#else
#define OO_END_SUBCLASS_TRACE(class)
#endif

#define OO_END_SUBCLASS(class)\
OO_END_SUBCLASS_CHECK(class);\
OO_END_SUBCLASS_TRACE(class)


#define OO_BEGIN_CLASS(class) OO_BEGIN_SUBCLASS(class,Root)
#define OO_END_CLASS(class) OO_END_SUBCLASS(class)


#define OO_BEGIN_STRUCT(class) OO_BEGIN_SUBCLASS(class,RootStruct)
#define OO_END_STRUCT(class) OO_END_SUBCLASS(class)


#ifdef OO_CHECK
#define OO_GET_CHECK(instance,class,property)\
if (isNil { OO_##class }) exitWith { diag_log format ["OO_GET: ERROR: undefined class %1", #class] };\
if (isNil { OO_##class##_Property_##property }) exitWith { diag_log format ["OO_GET: ERROR: undefined property %2 (class %1)", #class, #property] };\
if (isNil { instance }) exitWith { diag_log format ["OO_GET: ERROR: undefined instance %3 (class %1, property %2)", #class, #property, #instance] };\
if (OO_ISCLASS(class) && { OO_ISNULL(instance) }) exitWith { diag_log format ["OO_GET: ERROR: NULL instance %3 (class %1, property %2)", #class, #property, #instance] };\
if (not OO_INSTANCE_ISOFCLASS(instance,class)) exitWith { diag_log format["OO_GET: ERROR: instance '%3' is not of class '%1'", #class, #property, #instance] };\
if (OO_##class##_Property_##property > count (instance)) exitWith { diag_log format ["OO_GET: ERROR: property index out of range for instance %3 (class %1, property %2)", #class, #property, #instance] };
#else
#define OO_GET_CHECK(instance,class,property)
#endif

#ifdef OO_TRACE_GET
#define OO_GET_TRACE(instance,class,property)\
diag_log format ["%1OO_GET: get instance %6 %3 %2,%4 value %5", if (isNil "_TRACE_INDENT") then { "" } else { _TRACE_INDENT }, #class, if (OO_ISCLASS(class)) then { OO_INSTANCE_ID(instance) } else { "STRUCT" }, #property, (instance) select OO_##class##_Property_##property, OO_CLASS_NAME(OO_INSTANCE_CLASS(instance))];
#else
#define OO_GET_TRACE(instance,class,property,value)
#endif

#ifdef OO_CHECK
#define OO_GET(instance,class,property)\
(call {\
OO_GET_CHECK(instance,class,property)\
OO_GET_TRACE(instance,class,property)\
(instance) select OO_##class##_Property_##property\
})
#else
#define OO_GET(instance,class,property)\
((instance) select OO_##class##_Property_##property)
#endif

#define OO_GETREF(instance,class,property)\
(call {\
OO_GET_CHECK(instance,class,property);\
[(instance), OO_CLASSNAME_PROPERTY_TABLE(class), OO_##class##_Property_##property] call OO_GET_INDIRECT\
})

#ifdef OO_TRACE
OO_ValueDescription =
{
	params ["_value"];

	if (isNil "_value") exitWith{ "nil" };

	switch (typeName _value) do
	{
		case typeName[]: { _value = format["[%1] %2", count _value, _value]; if (count _value <= 30) then { _value } else { format["%1...]", _value select[0, 30]] } };
		case typeName{}: { "CODE" };
		default { format ["%1 %2", typeName _value, _value] };
	};
};
#endif

//TODO: Type checking to generate warning
#ifdef OO_CHECK
#define OO_SET_CHECK(instance,class,property,value)\
if (isNil{ OO_##class }) exitWith{ diag_log format["OO_SET: ERROR: undefined class %1", #class] }; \
if (isNil { OO_##class##_Property_##property }) exitWith { diag_log format ["OO_SET: ERROR: undefined property %2 (class %1)", #class, #property] }; \
if (isNil { instance }) exitWith { diag_log format ["OO_SET: ERROR: undefined instance %3 (class %1, property %2)", #class, #property, #instance] }; \
if (OO_ISCLASS(class) && { OO_ISNULL(instance) }) exitWith { diag_log format ["OO_SET: ERROR: NULL instance %3 (class %1, property %2)", #class, #property, #instance] }; \
if (not OO_INSTANCE_ISOFCLASS(instance,class)) exitWith { diag_log format["OO_GET: ERROR: instance '%3' is not of class '%1'", #class, #property, #instance] }; \
if (OO_##class##_Property_##property > count instance) exitWith { diag_log format ["OO_SET: ERROR: property index out of range for instance %3 (class %1, property %2)", #class, #property, #instance] }; \
if (isNil { value }) exitWith { diag_log format ["OO_SET: ERROR: undefined value (class %1, property %2)", #class, #property] };
#else
#define OO_SET_CHECK(instance,class,property,value)
#endif

#ifdef OO_TRACE
#define OO_SET_TRACE(instance,class,property,value)\
diag_log format ["%1OO_SET: set instance %6 %3 %2,%4 to %5", if (isNil "_TRACE_INDENT") then { "" } else { _TRACE_INDENT }, #class, if (OO_ISCLASS(class)) then { OO_INSTANCE_ID(instance) } else { "STRUCT" }, #property, [value] call OO_ValueDescription, OO_CLASS_NAME(OO_INSTANCE_CLASS(instance))];
#else
#define OO_SET_TRACE(instance,class,property,value)
#endif

#define OO_SET(instance,class,property,value)\
OO_SET_CHECK(instance,class,property,value)\
OO_SET_TRACE(instance,class,property,value)\
(instance) set [OO_##class##_Property_##property, (value)]

#define OO_SETREF(instance,class,property,value)\
OO_SET_CHECK(instance,class,property,value)\
OO_SET_TRACE(instance,class,property,value)\
[(instance), OO_CLASSNAME_PROPERTY_TABLE(class), OO_##class##_Property_##property, (value)] call OO_SET_INDIRECT


#ifdef OO_CHECK
#define OO_METHOD_CHECK(instance,class,method)\
if (isNil { OO_##class }) exitWith{ diag_log format["OO_METHOD: ERROR: undefined class %1", #class] };\
if (isNil { OO_##class##_Method_##method }) exitWith { diag_log format ["OO_METHOD: ERROR: undefined method %2 (class %1)", #class, #method] };\
if (isNil { instance }) exitWith { diag_log format ["OO_METHOD: ERROR: undefined instance %3 (class %1, method %2)", #class, #method, #instance] };\
if (typeName (instance) != typeName []) exitWith { diag_log format ["OO_METHOD: ERROR: instance not an array %3 '%4' (class %1, method %2)", #class, #method, #instance, instance] };\
if (OO_ISCLASS(class) && { OO_ISNULL(instance) }) exitWith { diag_log format ["OO_METHOD: ERROR: NULL instance %3 (class %1, method %2)", #class, #method, #instance] }
#else
#define OO_METHOD_CHECK(instance,class,method)
#endif

#define OO_METHOD(instance,class,method)\
{\
	OO_METHOD_CHECK(instance,class,method);\
	([instance] + _this) call ((OO_CLASSINDEX_METHOD_TABLE(OO_INSTANCE_CLASSINDEX(instance))) select OO_##class##_Method_##method)\
}

#define OO_REFERENCE(instance) [OO_INSTANCE_CLASSINDEX(instance), OO_INSTANCE_ID(instance)]
#define OO_INSTANCE(reference) ([OO_CLASSINDEX_REFERENCE_TABLE((reference) select 0), (reference) select 1] call REF_GetValue)


#ifdef OO_TRACE
#define OO_CREATECLASS_TRACE(class)\
diag_log format ["CONSTRUCTOR: %1 %2", OO_CLASSINDEX_CLASS_NAME(OO_INSTANCE_CLASSINDEX(_instance)), OO_INSTANCE_ID(_instance)]
#else
#define OO_CREATECLASS_TRACE(class)
#endif

#define OO_CREATECLASS(class)\
{\
	private _instance = [];\
	{ _instance set [_forEachIndex, if (isNil { _x select 1 }) then { nil } else { if (typeName (_x select 1) == "ARRAY") then { +(_x select 1) } else { _x select 1 } }] } forEach OO_CLASSNAME_PROPERTY_TABLE(class);\
	_instance set [0, OO_##class];\
	[OO_CLASSNAME_REFERENCE_TABLE(class), _instance] call REF_AddValue;\
	_this call OO_METHOD(_instance,Root,Create);\
	OO_CREATECLASS_TRACE(class);\
	_instance\
}


#ifdef OO_TRACE
#define OO_CREATESTRUCT_TRACE(class)\
diag_log format ["CONSTRUCTOR: %1", OO_CLASSINDEX_CLASS_NAME(OO_INSTANCE_CLASSINDEX(_instance))]
#else
#define OO_CREATESTRUCT_TRACE(class)
#endif

#define OO_CREATESTRUCT(class)\
{\
	private _instance = [];\
	{ _instance pushBack (if (typeName (_x select 1) == "ARRAY") then { +(_x select 1) } else { _x select 1 }) } forEach OO_CLASSNAME_PROPERTY_TABLE(class);\
	_instance set [0, OO_##class];\
	_this call OO_METHOD(_instance,RootStruct,Create);\
	OO_CREATESTRUCT_TRACE(class);\
	_instance\
}

#define OO_CREATE(class)\
{\
	if (OO_ISCLASS(class)) then OO_CREATECLASS(class) else OO_CREATESTRUCT(class) \
}


#ifdef OO_TRACE
#define OO_DELETE_TRACE(instance)\
diag_log format["DESTRUCTOR: %1 %2", OO_CLASSINDEX_CLASS_NAME(OO_INSTANCE_CLASSINDEX(instance)), OO_INSTANCE_ID(instance)]
#else
#define OO_DELETE_TRACE(instance)
#endif

#define OO_DELETE(instance)\
{\
	OO_DELETE_TRACE(instance);\
	[] call OO_METHOD(instance,Root,Delete); \
	[OO_INSTANCE_REFERENCE_TABLE(instance), (instance)] call REF_RemoveValue\
}

#define OO_METHOD_PARENT(instance,class,name,parent)\
{\
	private _parentClass = OO_CLASSNAME_CLASS(parent);\
	private _parentMethodTable = OO_CLASS_METHOD_TABLE(_parentClass);\
	([instance] + _this) call (_parentMethodTable select OO_##class##_Method_##name);\
}

#define OO_FOREACHINSTANCE(class,parameters,code)\
([OO_##class, (parameters), (code)] call OO_FOREACHINSTANCE_BODY)

#ifdef OO_TRACE
#define OO_TRACE_DECL(method)\
diag_log format["OO_TRACE_DECL(%1)", #method];\
method =\
{\
	_TRACE_INDENT = if (isNil "_TRACE_INDENT") then { "" } else { _TRACE_INDENT };\
	diag_log format["%1%2 %3", _TRACE_INDENT, #method, _this apply { if (isNil "_x") then { "nil" } else { [_x] call OO_ValueDescription } }];\
	_TRACE_INDENT = _TRACE_INDENT + "   ";\
	private _start = diag_tickTime;\
	private _result = if (isNil "_this") then { call method##_Actual } else { _this call method##_Actual }; \
	private _elapsed = diag_tickTime - _start;\
	_TRACE_INDENT = _TRACE_INDENT select [3];\
	diag_log format["%1%2 %3 elapsed %4ms", _TRACE_INDENT, #method, if (isNil "_result") then { "nil" } else { [_result] call OO_ValueDescription }, round (_elapsed * 1000)];\
	if (isNil "_result") exitWith {};\
	_result\
};\
method##_Actual
#else
#define OO_TRACE_DECL(method) method
#endif

#ifdef OO_TRACE
#define OO_TRACE_SYMBOL(symbol) diag_log format [#symbol + ": %1", symbol]
#else
#define OO_TRACE_SYMBOL(symbol)
#endif