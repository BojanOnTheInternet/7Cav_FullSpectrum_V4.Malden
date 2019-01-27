params ["_weapon"];

not (_weapon isKindOf ["CarHorn", configFile >> "CfgWeapons"]) && { not (_weapon isKindOf ["SmokeLauncher", configFile >> "CfgWeapons"]) }  && { not (_weapon isKindOf ["Laserdesignator_mounted", configFile >> "CfgWeapons"]) }
