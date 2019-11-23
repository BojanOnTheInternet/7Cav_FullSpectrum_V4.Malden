if (not isServer && hasInterface) exitWith {};

// Infantry

SPM_InfantryGarrison_RatingsCivilian = "toLower (configName _x) find 'c_man' == 0" configClasses (configFile >> "CfgVehicles");
SPM_InfantryGarrison_CallupsCivilian = SPM_InfantryGarrison_RatingsCivilian apply { [configName _x, [1, 1, 1.0]] };
SPM_InfantryGarrison_RatingsCivilian = SPM_InfantryGarrison_RatingsCivilian apply { [configName _x, [1, 1]] };