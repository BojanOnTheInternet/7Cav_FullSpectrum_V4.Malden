class JB_CE_Dialog
{
	idd = 3400;
	movingEnable = false;
	moving = 1;
	onUnload = "_this call JB_CE_Unload";

	class controlsBackground
	{
		class iBackgroundLeft : RscText
		{
			idc = 1000;
			text = "";
			x = "safeZoneX + safeZoneW * (0.00 + 0.03)";
			y = 0.00;
			w = "safeZoneW * (0.50 - 0.01 - 0.03)";
			h = 1.00;
			colorBackground[] = { 0, 0, 0, 0.4 };
		};

		class iBackgroundRight : RscText
		{
			idc = 1001;
			text = "";
			x = "safeZoneX + safeZoneW * (0.50 + 0.01)";
			y = 0.00;
			w = "safeZoneW * (0.50 - 0.01 - 0.03)";
			h = 1.00;
			colorBackground[] = { 0, 0, 0, 0.4 };
		};

		class iBackgroundAllItems : RscText
		{
			idc = 1002;
			text = "";
			x = "safeZoneX + safeZoneW * (0.00 + 0.03)";
			y = 0.16;
			w = "safeZoneW * (0.50 - 0.01 - 0.03)";
			h = 0.81;
			colorBackground[] = { 0, 0, 0, 0.4 };
		};

		class iBackgroundContainerItems : RscText
		{
			idc = 1003;
			text = "";
			x = "safeZoneX + safeZoneW * (0.50 + 0.01)";
			y = 0.16;
			w = "safeZoneW * (0.50 - 0.01 - 0.03)";
			h = 0.81;
			colorBackground[] = { 0, 0, 0, 0.4 };
		};

		class iTitleAllItems : RscText
		{
			idc = 1004;
			text = "Arsenal item types";
			sizeEx = "safeZoneH * 0.035";
			x = "safeZoneX + safeZoneW * 0.03";
			y = -0.04;
			w = "safeZoneW * (0.50 - 0.01 - 0.03)";
			h = 0.04;
			colorBackground[] = { 0, 0, 0, 0.8 };
		};

		class iTitleContainerItems : RscText
		{
			idc = 1005;
			text = "Container";
			sizeEx = "safeZoneH * 0.035";
			x = "safeZoneX + safeZoneW * (0.50 + 0.01)";
			y = -0.04;
			w = "safeZoneW * (0.50 - 0.01 - 0.03)";
			h = 0.04;
			colorBackground[] = { 0, 0, 0, 0.8 };
		};
	};

	class controls
	{
		class iClearButton : RscButton
		{
			idc = 1200;
			text = "CLEAR";
			sizeEx = "safeZoneH * 0.035";
			x = "safeZoneX + safeZoneW * (0.50 + 0.01)";
			y = 1.00;
			w = "safeZoneW * 0.10";
			h = 0.05;
			action = "[findDisplay 3400 displayCtrl 1200] call JB_CE_ClearInventory";
		};

		class iOKButton : RscButton
		{
			idc = 1201;
			text = "OK";
			sizeEx = "safeZoneH * 0.035";
			x = "safeZoneX + safeZoneW * (1.00 - 0.03 - 0.22)";
			y = 1.00;
			w = "safeZoneW * 0.10";
			h = 0.05;
			action = "findDisplay 3400 closeDisplay 1";
			deletable = 1;
		};

		class iCancelButton : RscButton
		{
			idc = 1202;
			text = "CANCEL";
			sizeEx = "safeZoneH * 0.035";
			x = "safeZoneX + safeZoneW * (1.00 - 0.03 - 0.10)";
			y = 1.00;
			w = "safeZoneW * 0.10";
			h = 0.05;
			action = "findDisplay 3400 closeDisplay 2";
		};

		class iAllItems : RscListNBox
		{
			idc = 1203;
			x = "safeZoneX + safeZoneW * 0.03";
			y = 0.16;
			w = "safeZoneW * (0.50 - 0.01 - 0.03)";
			h = 0.81;
			sizeEx = "safeZoneH * 0.035";
			columns[] = { 0.02, 0.07, 0.16, 0.83, 0.88, 0.93 };
			onKeyDown = "(_this + [JB_CE_GearAllCurrentCategory select 2]) call JB_CE_GearKeyDown";
			onMouseButtonUp = "(_this + [JB_CE_GearAllCurrentCategory select 2, 1]) call JB_CE_GearMouseButtonUp";
//			onMouseButtonDblClick = "(_this + [JB_CE_GearAllCurrentCategory select 2, 2]) call JB_CE_GearMouseButtonDblClick";
		};

		class iContainerItems : RscListNBox
		{
			idc = 1204;
			x = "safeZoneX + safeZoneW * (0.50 + 0.01)";
			y = 0.16;
			w = "safeZoneW * (0.50 - 0.01 - 0.03)";
			h = 0.81;
			sizeEx = "safeZoneH * 0.035";
			columns[] = { 0.02, 0.07, 0.16, 0.83, 0.88, 0.93 };
			onKeyDown = "(_this + [JB_CE_GearContainerItems]) call JB_CE_GearKeyDown";
			onMouseButtonUp = "(_this + [JB_CE_GearContainerItems, 1]) call JB_CE_GearMouseButtonUp";
//			onMouseButtonDblClick = "(_this + [JB_CE_GearContainerItems, 2]) call JB_CE_GearMouseButtonDblClick";
		};

		class iFill : RscProgress
		{
			idc = 1205;
			x = "safeZoneX + safeZoneW * (0.50 + 0.01)";
			y = 0.97;
			w = "safeZoneW * (0.50 - 0.01 - 0.03)";
			h = 0.03;
			colorBar[] = {1, 1, 1, 1};
			colorFrame[] = {0, 0, 0, 0};
		};

		// Category buttons

		class iPrimaryWeaponPicture : RscPicture
		{
			idc = 1301;
			x = "safeZoneX + safeZoneW * (0.00 + 0.06)";
			y = 0.00;
			w = 0.05;
			h = 0.07;
			text = "\A3\UI_f\Data\GUI\Rsc\RscDisplayArsenal\primaryWeapon_ca.paa";
		};

		class iPrimaryWeaponButton : RscButton
		{
			idc = 1302;
			x = "safeZoneX + safeZoneW * (0.00 + 0.06)";
			y = 0.00;
			w = 0.05;
			h = 0.07;
			colorBackground[] = {0, 0, 0, 0};
			colorBackgroundActive[] = {0, 0, 0, 0};
			colorFocused[] = {0, 0, 0, 0};
			action = "[['primaryWeapons'] call JB_CE_GearAllGetCategory] call JB_CE_GearShowAll";
		};

		class iHandgunWeaponPicture : RscPicture
		{
			idc = 1303;
			x = "safeZoneX + safeZoneW * (0.06 + 0.06)";
			y = 0.00;
			w = 0.05;
			h = 0.07;
			text = "\A3\UI_f\Data\GUI\Rsc\RscDisplayArsenal\handgun_ca.paa";
		};

		class iHandgunWeaponButton : RscButton
		{
			idc = 1304;
			x = "safeZoneX + safeZoneW * (0.06 + 0.06)";
			y = 0.00;
			w = 0.05;
			h = 0.07;
			colorBackground[] = {0, 0, 0, 0};
			colorBackgroundActive[] = {0, 0, 0, 0};
			colorFocused[] = {0, 0, 0, 0};
			action = "[['handgunWeapons'] call JB_CE_GearAllGetCategory] call JB_CE_GearShowAll";
		};

		class iSecondaryWeaponPicture : RscPicture
		{
			idc = 1305;
			x = "safeZoneX + safeZoneW * (0.12 + 0.06)";
			y = 0.00;
			w = 0.05;
			h = 0.07;
			text = "\A3\UI_f\Data\GUI\Rsc\RscDisplayArsenal\secondaryWeapon_ca.paa";
		};

		class iSecondaryWeaponButton : RscButton
		{
			idc = 1306;
			x = "safeZoneX + safeZoneW * (0.12 + 0.06)";
			y = 0.00;
			w = 0.05;
			h = 0.07;
			colorBackground[] = {0, 0, 0, 0};
			colorBackgroundActive[] = {0, 0, 0, 0};
			colorFocused[] = {0, 0, 0, 0};
			action = "[['secondaryWeapons'] call JB_CE_GearAllGetCategory] call JB_CE_GearShowAll";
		};

		class iUniformsPicture : RscPicture
		{
			idc = 1307;
			x = "safeZoneX + safeZoneW * (0.18 + 0.06)";
			y = 0.00;
			w = 0.05;
			h = 0.07;
			text = "\A3\UI_f\Data\GUI\Rsc\RscDisplayArsenal\uniform_ca.paa";
		};

		class iUniformsButton : RscButton
		{
			idc = 1308;
			x = "safeZoneX + safeZoneW * (0.18 + 0.06)";
			y = 0.00;
			w = 0.05;
			h = 0.07;
			colorBackground[] = {0, 0, 0, 0};
			colorBackgroundActive[] = {0, 0, 0, 0};
			colorFocused[] = {0, 0, 0, 0};
			action = "[['uniforms'] call JB_CE_GearAllGetCategory] call JB_CE_GearShowAll";
		};

		class iBackpacksPicture : RscPicture
		{
			idc = 1309;
			x = "safeZoneX + safeZoneW * (0.24 + 0.06)";
			y = 0.00;
			w = 0.05;
			h = 0.07;
			text = "\A3\UI_f\Data\GUI\Rsc\RscDisplayArsenal\Backpack_ca.paa";
		};

		class iBackpacksButton : RscButton
		{
			idc = 1310;
			x = "safeZoneX + safeZoneW * (0.24 + 0.06)";
			y = 0.00;
			w = 0.05;
			h = 0.07;
			colorBackground[] = {0, 0, 0, 0};
			colorBackgroundActive[] = {0, 0, 0, 0};
			colorFocused[] = {0, 0, 0, 0};
			action = "[['backpacks'] call JB_CE_GearAllGetCategory] call JB_CE_GearShowAll";
		};

		class iVestsPicture : RscPicture
		{
			idc = 1311;
			x = "safeZoneX + safeZoneW * (0.30 + 0.06)";
			y = 0.00;
			w = 0.05;
			h = 0.07;
			text = "\A3\UI_f\Data\GUI\Rsc\RscDisplayArsenal\vest_ca.paa";
		};

		class iVestsButton : RscButton
		{
			idc = 1312;
			x = "safeZoneX + safeZoneW * (0.30 + 0.06)";
			y = 0.00;
			w = 0.05;
			h = 0.07;
			colorBackground[] = {0, 0, 0, 0};
			colorBackgroundActive[] = {0, 0, 0, 0};
			colorFocused[] = {0, 0, 0, 0};
			action = "[['vests'] call JB_CE_GearAllGetCategory] call JB_CE_GearShowAll";
		};

		class iHeadgearPicture : RscPicture
		{
			idc = 1313;
			x = "safeZoneX + safeZoneW * (0.36 + 0.06)";
			y = 0.00;
			w = 0.05;
			h = 0.07;
			text = "\A3\UI_f\Data\GUI\Rsc\RscDisplayArsenal\headgear_ca.paa";
		};

		class iHeadgearButton : RscButton
		{
			idc = 1314;
			x = "safeZoneX + safeZoneW * (0.36 + 0.06)";
			y = 0.00;
			w = 0.05;
			h = 0.07;
			colorBackground[] = {0, 0, 0, 0};
			colorBackgroundActive[] = {0, 0, 0, 0};
			colorFocused[] = {0, 0, 0, 0};
			action = "[['headgear'] call JB_CE_GearAllGetCategory] call JB_CE_GearShowAll";
		};

		class iMagazinesCurrentPicture : RscPicture
		{
			idc = 1315;
			x = "safeZoneX + safeZoneW * (0.00 + 0.06)";
			y = 0.08;
			w = 0.05;
			h = 0.07;
			text = "\A3\UI_f\Data\GUI\Rsc\RscDisplayArsenal\cargoMag_ca.paa";
		};

		class iMagazinesCurrentButton : RscButton
		{
			idc = 1316;
			x = "safeZoneX + safeZoneW * (0.00 + 0.06)";
			y = 0.08;
			w = 0.05;
			h = 0.07;
			colorBackground[] = {0, 0, 0, 0};
			colorBackgroundActive[] = {0, 0, 0, 0};
			colorFocused[] = {0, 0, 0, 0};
			action = "[['magazinesCurrent'] call JB_CE_GearAllGetCategory] call JB_CE_GearShowAll";
		};

		class iMagazinesWeaponsPicture : RscPicture
		{
			idc = 1317;
			x = "safeZoneX + safeZoneW * (0.06 + 0.06)";
			y = 0.08;
			w = 0.05;
			h = 0.07;
			text = "\A3\UI_f\Data\GUI\Rsc\RscDisplayArsenal\cargoMagAll_ca.paa";
		};

		class iMagazinesWeaponsButton : RscButton
		{
			idc = 1318;
			x = "safeZoneX + safeZoneW * (0.06 + 0.06)";
			y = 0.08;
			w = 0.05;
			h = 0.07;
			colorBackground[] = {0, 0, 0, 0};
			colorBackgroundActive[] = {0, 0, 0, 0};
			colorFocused[] = {0, 0, 0, 0};
			action = "[['magazinesWeapons'] call JB_CE_GearAllGetCategory] call JB_CE_GearShowAll";
		};

		class iMagazinesThrownPicture : RscPicture
		{
			idc = 1319;
			x = "safeZoneX + safeZoneW * (0.12 + 0.06)";
			y = 0.08;
			w = 0.05;
			h = 0.07;
			text = "\A3\UI_f\Data\GUI\Rsc\RscDisplayArsenal\cargoThrow_ca.paa";
		};

		class iMagazinesThrownButton : RscButton
		{
			idc = 1320;
			x = "safeZoneX + safeZoneW * (0.12 + 0.06)";
			y = 0.08;
			w = 0.05;
			h = 0.07;
			colorBackground[] = {0, 0, 0, 0};
			colorBackgroundActive[] = {0, 0, 0, 0};
			colorFocused[] = {0, 0, 0, 0};
			action = "[['magazinesThrown'] call JB_CE_GearAllGetCategory] call JB_CE_GearShowAll";
		};

		class iMagazinesPutPicture : RscPicture
		{
			idc = 1321;
			x = "safeZoneX + safeZoneW * (0.18 + 0.06)";
			y = 0.08;
			w = 0.05;
			h = 0.07;
			text = "\A3\UI_f\Data\GUI\Rsc\RscDisplayArsenal\cargoPut_ca.paa";
		};

		class iMagazinesPutButton : RscButton
		{
			idc = 1322;
			x = "safeZoneX + safeZoneW * (0.18 + 0.06)";
			y = 0.08;
			w = 0.05;
			h = 0.07;
			colorBackground[] = {0, 0, 0, 0};
			colorBackgroundActive[] = {0, 0, 0, 0};
			colorFocused[] = {0, 0, 0, 0};
			action = "[['magazinesPut'] call JB_CE_GearAllGetCategory] call JB_CE_GearShowAll";
		};

		class iAttachmentsPicture : RscPicture
		{
			idc = 1323;
			x = "safeZoneX + safeZoneW * (0.24 + 0.06)";
			y = 0.08;
			w = 0.05;
			h = 0.07;
			text = "\A3\UI_f\Data\GUI\Rsc\RscDisplayArsenal\itemOptic_ca.paa";
		};

		class iAttachmentsButton : RscButton
		{
			idc = 1324;
			x = "safeZoneX + safeZoneW * (0.24 + 0.06)";
			y = 0.08;
			w = 0.05;
			h = 0.07;
			colorBackground[] = {0, 0, 0, 0};
			colorBackgroundActive[] = {0, 0, 0, 0};
			colorFocused[] = {0, 0, 0, 0};
			action = "[['attachments'] call JB_CE_GearAllGetCategory] call JB_CE_GearShowAll";
		};

		class iMiscellaneousPicture : RscPicture
		{
			idc = 1325;
			x = "safeZoneX + safeZoneW * (0.30 + 0.06)";
			y = 0.08;
			w = 0.05;
			h = 0.07;
			text = "\A3\UI_f\Data\GUI\Rsc\RscDisplayArsenal\cargoMisc_ca.paa";
		};

		class iMiscellaneousButton : RscButton
		{
			idc = 1326;
			x = "safeZoneX + safeZoneW * (0.30 + 0.06)";
			y = 0.08;
			w = 0.05;
			h = 0.07;
			colorBackground[] = {0, 0, 0, 0};
			colorBackgroundActive[] = {0, 0, 0, 0};
			colorFocused[] = {0, 0, 0, 0};
			action = "[['miscellaneous'] call JB_CE_GearAllGetCategory] call JB_CE_GearShowAll";
		};
	};
};