if (not isServer && hasInterface) exitWith {};

// Air defense

SPM_AirDefense_CallupsEast =
[
	["LOP_US_ZSU234", [60, 1, 1.0,
		{
			params ["_unit"];

			_unit engineOn true;

		}]],
	["LOP_US_Igla_AA_pod", [60, 1, 1.0,
		{
			params ["_unit"];
		}]]
];

SPM_AirDefense_RatingsEast = SPM_AirDefense_CallupsEast apply { [_x select 0, (_x select 1) select [0, 2]] };

// Air patrol

SPM_AirPatrol_CallupsEast =
[
	["rhs_mig29s_vvs", [100, 1, 1.0,
			{
				params ["_unit"];

				{
					if (_x in ["rhs_ammo_r27_base", "rhs_ammo_r73m"]) then { _unit setAmmoOnPylon [_forEachIndex + 1, 0]; _unit setPylonLoadOut [_forEachIndex + 1, ""] };
				} forEach getPylonMagazines _unit;

				_unit removeWeapon "rhs_weap_r27r_Launcher";
				_unit removeWeapon "rhs_weap_r27t_Launcher";

				_unit engineOn true;
				_unit setVelocityModelSpace [0, 300 * 0.2778, 0];
				_unit flyInHeight (100 + random 200);

				_unit setVariable ["SPM_Force_EssentialMagazines", [["rhs_ammo_r73m", 0], ["rhs_ammo_r73m", 0],["rhs_ammo_r73m", 0]]];
			}]],
	["rhs_mig29sm_vvs", [150, 1, 1.0,
			{
				params ["_unit"];

				{
					if (_x in ["rhs_ammo_r27_base", "rhs_ammo_r73m"]) then { _unit setAmmoOnPylon [_forEachIndex + 1, 0]; _unit setPylonLoadOut [_forEachIndex + 1, ""] };
				} forEach getPylonMagazines _unit;

				_unit removeWeapon "rhs_weap_r27r_Launcher";
				_unit removeWeapon "rhs_weap_r27t_Launcher";

				_unit engineOn true;
				_unit setVelocityModelSpace [0, 300 * 0.2778, 0];
				_unit flyInHeight (100 + random 200);

				_unit setVariable ["SPM_Force_EssentialMagazines", [["rhs_ammo_r73m", 0], ["rhs_ammo_r73m", 0],["rhs_ammo_r73m", 0]]];
			}]],

	["RHS_Su25SM_vvs", [100, 1, 1.0,
			{
				params ["_unit"];

				{
					if (_x in ["rhs_ammo_fab250", "rhs_ammo_s8_penetrator", "rhs_ammo_s8DF", "rhs_ammo_r60m"]) then { _unit setAmmoOnPylon [_forEachIndex + 1, 0]; _unit setPylonLoadOut [_forEachIndex + 1, ""] };
				} forEach getPylonMagazines _unit;

				_unit removeWeapon "rhs_weap_fab250";
				_unit removeWeapon "rhs_weap_s8df";

				_unit engineOn true;
				_unit setVelocityModelSpace [0, 300 * 0.2778, 0];
				_unit flyInHeight (100 + random 200);

				_unit setVariable ["SPM_Force_EssentialMagazines", [["rhs_ammo_r60m", 0], ["rhs_ammo_r60m", 0], ["rhs_ammo_s8_penetrator", 0], ["rhs_ammo_s8_penetrator", 0]]];
			}]]
];

SPM_AirPatrol_RatingsEast = SPM_AirPatrol_CallupsEast apply { [_x select 0, (_x select 1) select [0, 2]] };

// Armor

SPM_Armor_CallupsEastAPCs =
[
	["LOP_US_BMP2D",
		[20, 3, 0.5,
			{
			}]],
	["LOP_US_BMP1",
		[20, 3, 0.5,
			{
			}]],
	["LOP_US_BTR70",
		[20, 3, 1,
			{
				params ["_unit"];
				[_unit] spawn {
					params ["_unit"];
					// RHS bug, need to remove this crew member to move the vic
					waitUntil { sleep 1; count (fullCrew [_unit, "Turret"]) > 0 };
					deleteVehicle (fullCrew [_unit, "Turret"] select 0 select 0);
				}
			}]],
	["LOP_US_UAZ_SPG",
		[40, 1, 0.2, {}]]
			
];

SPM_Armor_RatingsEastAPCs = SPM_Armor_CallupsEastAPCs apply { [_x select 0, (_x select 1) select [0, 2]] };

// 120pts
SPM_Armor_CallupsEastTanks =
[
	["rhs_t80um",
		[60, 2, 0.8,
			{
				params ["_unit"];
				_unit addEventHandler ["Fired",{(_this select 0) setVehicleAmmo 1}];
			}]],
	["rhs_t90a_TV",
		[60, 2, 0.2,
			{				
				params ["_unit"];
				_unit addEventHandler ["Fired",{(_this select 0) setVehicleAmmo 1}];
			}]]
];


SPM_Armor_RatingsEastTanks = SPM_Armor_CallupsEastTanks apply { [_x select 0, (_x select 1) select [0, 2]] };

// 180pts
SPM_Armor_CallupsEastAir =
[
	["RHS_Ka52_vvsc", [180, 1, 0.2,
			{
			}]]
];

SPM_Armor_RatingsEastAir = SPM_Armor_CallupsEastAir apply { [_x select 0, (_x select 1) select [0, 2]] };

// Infantry

SPM_InfantryGarrison_RatingsEast =
[
    ["LOP_US_Infantry_Rifleman", [1, 1]],
    ["LOP_US_Infantry_Corpsman", [1, 1]],
    ["LOP_US_Infantry_Engineer", [1, 1]],
    ["LOP_US_Infantry_MG", [1, 1]],
    ["LOP_US_Infantry_MG_Asst", [1, 1]],
    ["LOP_US_Infantry_MG_2", [1, 1]],
    ["LOP_US_Infantry_AA", [1, 1]],
    ["LOP_US_Infantry_Marksman", [1, 1]],
    ["LOP_US_Infantry_Rifleman_1", [1, 1]],
    ["LOP_US_Infantry_Rifleman_2", [1, 1]],
    ["LOP_US_Infantry_Rifleman_3", [1, 1]],
    ["LOP_US_Infantry_Rifleman_4", [1, 1]],
    ["LOP_US_Infantry_AT", [1, 1]],
    ["LOP_US_Infantry_AT_Asst", [1, 1]],
    ["LOP_US_Infantry_GL", [1, 1]],
    ["LOP_US_Infantry_GL_2", [1, 1]],
    ["LOP_US_Infantry_TL", [1, 1]],
    ["LOP_US_Infantry_SL", [1, 1]],
    ["LOP_US_Infantry_Officer", [1, 1]]
];

SPM_InfantryGarrison_CallupsEast =
[
	[(configfile >> "CfgGroups" >> "East" >> "LOP_US" >> "Infantry" >> "LOP_US_Rifle_squad"), [1, 8, 1.0]]
];

SPM_InfantryGarrison_InitialCallupsEast =
[
	[(configfile >> "CfgGroups" >> "East" >> "LOP_US" >> "Infantry" >> "LOP_US_Patrol_section"), [1, 4, 1.0]],
	[(configfile >> "CfgGroups" >> "East" >> "LOP_US" >> "Infantry" >> "LOP_US_AA_section"), [1, 4, 0.30]],
	[(configfile >> "CfgGroups" >> "East" >> "LOP_US" >> "Infantry" >> "LOP_US_AT_section"), [1, 4, 0.60]],
	[(configfile >> "CfgGroups" >> "East" >> "LOP_US" >> "Infantry" >> "LOP_US_FT_section"), [1, 2, 1.0]]
];

SPM_InfantryGarrison_InitialCallupsEastAA =
[
	[(configfile >> "CfgGroups" >> "East" >> "LOP_US" >> "Infantry" >> "LOP_US_Patrol_section"), [1, 4, 1.0]],
	[(configfile >> "CfgGroups" >> "East" >> "LOP_US" >> "Infantry" >> "LOP_US_AA_section"), [1, 4, 1.0]],
	[(configfile >> "CfgGroups" >> "East" >> "LOP_US" >> "Infantry" >> "LOP_US_FT_section"), [1, 2, 1.0]]
];

SPM_InfantryGarrison_RatingsEastWater =
[
	["O_diver_TL_F", [1, 1]],
	["O_diver_exp_F", [1, 1]],
	["O_diver_F", [1, 1]]
];

SPM_InfantryGarrison_CallupsEastWater =
[
	[(configFile >> "CfgGroups" >> "East" >> "OPF_F" >> "SpecOps" >> "OI_diverTeam"), [1, 4, 1.0]]
];

SPM_InfantryGarrison_InitialCallupsEastWater =
[
	[(configFile >> "CfgGroups" >> "East" >> "OPF_F" >> "SpecOps" >> "OI_diverTeam"), [1, 4, 1.0]]
];

// Patrol cars

SPM_MissionAdvance_Patrol_CallupsEast =
[
	["LOP_US_UAZ_DshKM",
		[10, 1, 1.0, {}]],
	["LOP_US_UAZ_AGS",
		[15, 1, 1.0, {}]],
	["LOP_US_BMP2D",
		[20, 1, 1.0, {}]],
	["LOP_US_BTR60",
		[20, 1, 1.0, {}]]
];

SPM_MissionAdvance_Patrol_RatingsEast = SPM_MissionAdvance_Patrol_CallupsEast apply { [_x select 0, (_x select 1) select [0, 2]] };

// Transport

SPM_Transport_CallupsEastMohawk =
[
	["RHS_Mi8AMT_vvs", [1, 2, 1.0,
			{
				params ["_unit"];

				private _flyInHeight = 50;
				_unit setPos (getPos _unit vectorAdd [0,0,_flyInHeight]);
				_unit flyInHeight _flyInHeight;
			}]]
];

SPM_Transport_CallupsEastMarid =
[
	["rhs_tigr_m_msv", [1, 3, 2.0, {}]]
];

SPM_Transport_CallupsEastZamak =
[
	["LOP_US_Ural", [1, 3, 1.0, {}]],
	["LOP_US_Ural_open", [1, 3, 1.0, {}]]
];

SPM_Transport_CallupsEastSpeedboat =
[
	["O_Boat_Armed_01_hmg_F",
		[1, 3, 1.0,
			{
				params ["_unit"];

				[_unit] call SPM_Transport_RemoveWeapons;
				_unit addMagazine "500Rnd_65x39_Belt_Tracer_Green_Splash";
				_unit addWeapon "LMG_RCWS";
			}]]
];