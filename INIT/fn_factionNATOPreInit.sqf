if (not isServer && hasInterface) exitWith {};

// Air defense

SPM_AirDefense_RatingsWest =
[
	["B_Heli_Attack_01_F", [50, 2]],
	["B_Heli_Attack_01_dynamicLoadout_F", [50, 2]],
	["B_Heli_Light_01_armed_F", [20, 2]],
	["B_Heli_Light_01_dynamicLoadout_F", [20, 2]],
	["B_Plane_CAS_01_F", [120, 1]],
	["B_Plane_CAS_01_dynamicLoadout_F", [120, 1]],
	["B_Plane_Fighter_01_F", [120, 1]],
	["B_Plane_Fighter_01_Stealth_F", [120, 1]],
	["B_T_VTOL_01_armed_F", [60, 3]],

	["O_Heli_Attack_02_F", [50, 2]],
	["O_Heli_Attack_02_dynamicLoadout_F", [50, 2]],
	["O_Heli_Light_02_F", [20, 2]],
	["O_Heli_Light_02_dynamicLoadout_F", [20, 2]],
	["O_Plane_CAS_02_F", [120, 1]],
	["O_Plane_CAS_02_dynamicLoadout_F", [240, 1]],
//	["O_Plane_Fighter_02_F", [75, 1]],
//	["O_Plane_Fighter_02_Stealth_F", [75, 1]],

	["I_Heli_light_03_F", [20, 2]],
	["I_Heli_light_03_dynamicLoadout_F", [20, 2]],
//	["I_Plane_Fighter_03_CAS_F", [75, 1]],
//	["I_Plane_Fighter_03_AA_F", [75, 1]],
//	["I_Plane_Fighter_03_dynamicLoadout_F", [75, 1]],
//	["I_Plane_Fighter_04_F", [75, 1]]

	["RHS_AH64D", [50, 2]],
	["RHS_AH1Z", [50,2]],
	["FIR_A10C", [120, 1]],
	["FIR_F16C_Blank", [120, 1]]
];

// Air patrol

SPM_AirPatrol_RatingsWest =
[
	["B_Plane_Fighter_01_F", [200, 1]],
	["B_Plane_Fighter_01_Stealth_F", [200, 1]],

	["O_Plane_Fighter_02_F", [200, 1]],
	["O_Plane_Fighter_02_Stealth_F", [300, 1]],

	["I_Plane_Fighter_03_AA_F", [200, 1]],
	["I_Plane_Fighter_03_dynamicLoadout_F", [200, 1]],
	["I_Plane_Fighter_04_F", [200, 1]],

	["FIR_A10C", [100, 1]],
	["FIR_F16C_Blank", [200, 1]]
];

// Armor

_abrams_rating = 120;
SPM_Armor_RatingsWestTanks =
[
	//Abrams
	["rhsusf_m1a1aimd_usarmy", [_abrams_rating, 1]],
	["rhsusf_m1a1aim_tuski_d", [_abrams_rating, 1]],
	["rhsusf_m1a2sep1d_usarmy", [_abrams_rating, 1]],
	["rhsusf_m1a2sep1tuskid_usarmy", [_abrams_rating, 1]],
	["rhsusf_m1a2sep1tuskiid_usarmy", [_abrams_rating, 1]],
	["rhsusf_m1a1aimwd_usarmy", [_abrams_rating, 1]],
	["rhsusf_m1a1aim_tuski_wd", [_abrams_rating, 1]],
	["rhsusf_m1a2sep1wd_usarmy", [_abrams_rating, 1]],
	["rhsusf_m1a2sep1tuskiwd_usarmy", [_abrams_rating, 1]],
	["rhsusf_m1a2sep1tuskiiwd_usarmy", [_abrams_rating, 1]],

	//Slammer / Merkava
	["B_MBT_01_cannon_F", [40, 3]],
	["B_MBT_01_TUSK_F", [40, 3]],
	["B_T_MBT_01_cannon_F", [40, 3]],
	["B_T_MBT_01_TUSK_F", [40, 3]],

	//MBT-52 / Leopard 2
	["I_MBT_03_cannon_F", [_abrams_rating, 1]],

	// Tank DLC tank destroyer
	["B_AFV_Wheeled_01_cannon_F", [40, 3]],
	["B_AFV_Wheeled_01_up_cannon_F", [40, 3]],

	["O_MBT_04_cannon_F", [40, 3]],
	["O_MBT_02_cannon_F", [40, 3]],

	["I_MBT_03_cannon_F", [40, 3]]
];

_bradley_rating = 60;
SPM_Armor_RatingsWestAPCs =
[
	// Bradleys
	["RHS_M2A3", [_bradley_rating, 1]],
	["RHS_M2A3_BUSKI", [_bradley_rating, 1]],
	["RHS_M2A3_BUSKIII", [_bradley_rating, 1]],
	["RHS_M6", [_bradley_rating, 1]],
	["RHS_M2A2_wd", [_bradley_rating, 1]],
	["RHS_M2A2_BUSKI_WD", [_bradley_rating, 1]],
	["RHS_M2A3_wd", [_bradley_rating, 1]],
	["RHS_M2A3_BUSKI_wd", [_bradley_rating, 1]],
	["RHS_M2A3_BUSKIII_wd", [_bradley_rating, 1]],
	["RHS_M6_wd", [_bradley_rating, 1]],
	["RHS_M2A2", [_bradley_rating, 1]],
	["RHS_M2A2_BUSKI", [_bradley_rating, 1]],
	
	// Weisel
	["I_LT_01_cannon_F", [40, 1]],

	// Warrior
	["I_APC_tracked_03_cannon_F", [_bradley_rating, 1]],

	// NATO Vanilla APC
	["B_APC_Wheeled_01_cannon_F", [_bradley_rating, 1]],

	["O_APC_Tracked_02_cannon_F", [30, 3]],
	["O_APC_Wheeled_02_rcws_F", [20, 3]],

	["I_APC_tracked_03_cannon_F", [20, 3]],
	["I_APC_Wheeled_03_cannon_F", [20, 3]]
];

_apache_rating = 100;
_ah1z_rating = 100;
_littlebird_rating = 40;
_eagle_rating = 180;
SPM_Armor_RatingsWestAir =
[
	["RHS_AH64D", [_apache_rating, 1]],
	["RHS_AH64D_AA", [_apache_rating, 1]],
	["RHS_AH64D_noradar_AA", [_apache_rating, 1]],
	["RHS_AH64D_CS", [_apache_rating, 1]],
	["RHS_AH64D_noradar_CS", [_apache_rating, 1]],
	["RHS_AH64D_GS", [_apache_rating, 1]],
	["RHS_AH64D_noradar_GS", [_apache_rating, 1]],
	["RHS_AH64DGrey", [_apache_rating, 1]],
	["RHS_AH64D_wd", [_apache_rating, 1]],

	["LOP_AH1Z_CS_Base", [_ah1z_rating, 1]],
	["LOP_AH1Z_GS_Base", [_ah1z_rating, 1]],
	["RHS_AH1Z", [_ah1z_rating,1]],

	["RHS_MELB_AH6M", [_littlebird_rating, 1]],
	["RHS_MELB_AH6M_H", [_littlebird_rating, 1]],
	["RHS_MELB_AH6M_L", [_littlebird_rating, 1]],
	["RHS_MELB_AH6M_M", [_littlebird_rating, 1]],

	["FIR_A10C", [_eagle_rating, 1]],
	["FIR_F16C_Blank", [_eagle_rating, 1]],
	// There are like 20+ version of the F16, we only use the blank one

	//Vanilla hummingbird
	["B_Heli_Light_01_armed_F", [30, 2]],
	["B_Heli_Light_01_dynamicLoadout_F", [30, 2]],
	//Commanche
	["B_Heli_Attack_01_F", [75, 2]],
	["B_Heli_Attack_01_dynamicLoadout_F", [75, 2]],

	//A10D
	["B_Plane_CAS_01_F", [_eagle_rating, 1]],
	["B_Plane_CAS_01_dynamicLoadout_F", [_eagle_rating, 1]],

	// Armed blackfish
	["B_T_VTOL_01_armed_F", [240, 1]],

	["O_Plane_CAS_02_F", [_eagle_rating, 1]],
	["O_Plane_CAS_02_dynamicLoadout_F", [_eagle_rating, 1]],
	["O_Heli_Attack_02_F", [100, 2]],
	["O_Heli_Attack_02_dynamicLoadout_F", [100, 2]],
	["O_Heli_Light_02_F", [50, 2]],
	["O_Heli_Light_02_dynamicLoadout_F", [50, 2]],


	["I_Plane_Fighter_03_CAS_F", [75, 1]]
];

SPM_Armor_RatingsWestAirDefense =
[
	["B_APC_Tracked_01_AA_F", [50, 3]]
];

// Infantry

SPM_InfantryGarrison_RatingsWest =
[
	["rhsusf_army_ocp_officer", [1, 1]],
	["rhsusf_army_ocp_jfo", [1, 1]],
	["rhsusf_army_ocp_squadleader", [1, 1]],
	["rhsusf_army_ocp_teamleader", [1, 1]],
	["rhsusf_army_ocp_marksman", [1, 1]],
	["rhsusf_army_ocp_machinegunner", [1, 1]],
	["rhsusf_army_ocp_grenadier", [1, 1]],
	["rhsusf_army_ocp_engineer", [1, 1]],
	["rhsusf_army_ocp_medic", [1, 1]],
	["rhsusf_army_ocp_maaws", [1, 1]],
	["rhsusf_army_ocp_rifleman_m4", [1, 1]],
	["rhsusf_army_ocp_rifleman_m4", [1, 1]],
	["rhsusf_army_ocp_sniper_m24sws", [1, 1]],
	["B_T_Soldier_SL_F", [1,1]],
	["B_T_Soldier_TL_F", [1,1]],
	["B_T_Soldier_Repair_F", [1,1]],
	["B_T_soldier_mine_F", [1,1]],
	["B_T_Soldier_Exp_F", [1,1]],
	["B_T_Soldier_Engineer_F", [1,1]],
	["rhsusf_army_ocp_combatcrewman", [1,1]],
	["rhsusf_army_ocp_crewman", [1,1]],
	["rhsusf_army_ocp_officer", [1,1]],
	["rhsusf_army_ocp_driver", [1,1]],
	["rhsusf_army_ocp_arb_riflemanl", [1,1]],
	["rhsusf_army_ocp_arb_squadleader", [1,1]],
	["rhsusf_army_ocp_arb_teamleader", [1,1]],
	["rhsusf_army_ocp_arb_autorifleman", [1,1]],
	["rhsusf_army_ocp_arb_grenadier", [1,1]],
	["rhsusf_army_ocp_arb_rifleman", [1,1]],
	["rhsusf_army_ocp_arb_medic", [1,1]],
	["rhsusf_navy_marpat_wd_medic", [1,1]]
];

// Patrol cars

SPM_MissionAdvance_Patrol_RatingsWest =
[	
	["rhsusf_army_ocp_officer", [10, 1]],
	["rhsusf_army_ocp_jfo", [10, 1]],
	["rhsusf_army_ocp_squadleader", [10, 1]],
	["rhsusf_army_ocp_teamleader", [10, 1]],
	["rhsusf_army_ocp_marksman", [10, 1]],
	["rhsusf_army_ocp_machinegunner", [10, 1]],
	["rhsusf_army_ocp_grenadier", [10, 1]],
	["rhsusf_army_ocp_engineer", [10, 1]],
	["rhsusf_army_ocp_medic", [10, 1]],
	["rhsusf_army_ocp_maaws", [10, 1]],
	["rhsusf_army_ocp_rifleman_m4", [10, 1]],
	["rhsusf_army_ocp_rifleman_m4", [10, 1]],
	["rhsusf_army_ocp_sniper_m24sws", [10, 1]],
	["B_T_Soldier_SL_F", [10,1]],
	["B_T_Soldier_TL_F", [10,1]],
	["B_T_Soldier_Repair_F", [10,1]],
	["B_T_soldier_mine_F", [10,1]],
	["B_T_Soldier_Exp_F", [10,1]],
	["B_T_Soldier_Engineer_F", [10,1]],
	["rhsusf_army_ocp_combatcrewman", [10,1]],
	["rhsusf_army_ocp_crewman", [10,1]],
	["rhsusf_army_ocp_officer", [10,1]],
	["rhsusf_army_ocp_driver", [10,1]],
	["rhsusf_army_ocp_arb_riflemanl", [10,1]],
	["rhsusf_army_ocp_arb_squadleader", [10,1]],
	["rhsusf_army_ocp_arb_teamleader", [10,1]],
	["rhsusf_army_ocp_arb_autorifleman", [10,1]],
	["rhsusf_army_ocp_arb_grenadier", [10,1]],
	["rhsusf_army_ocp_arb_rifleman", [10,1]],
	["rhsusf_army_ocp_arb_medic", [10,1]],
	["rhsusf_navy_marpat_wd_medic", [10,1]]
];

