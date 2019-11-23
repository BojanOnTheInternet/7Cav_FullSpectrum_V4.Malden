class JBR_Repair
{
	idd = 2800;
	movingEnable = false;
	moving = 1;
	onUnload = "_this call JBR_RepairUnload";

	class controlsBackground
	{
		class iTitle : RscText
		{
			idc = 1100;
			text = "VEHICLE REPAIR";
			x = 0.25;
			y = 0.15;
			w = 0.50;
			h = 0.04;
			colorBackground[] = { "(profilenamespace getvariable ['GUI_BCG_RGB_R',0.3843])", "(profilenamespace getvariable ['GUI_BCG_RGB_G',0.7019])", "(profilenamespace getvariable ['GUI_BCG_RGB_B',0.8862])", "(profilenamespace getvariable ['GUI_BCG_RGB_A',0.7])" };
		};
		class iBackground : RscText
		{
			idc = 1130;
			text = "";
			x = 0.25;
			y = 0.19;
			w = 0.50;
			h = 0.47;
			colorBackground[] = { 0, 0, 0, 0.7 };
		};
		class iHeaderBand : RscText
		{
			idc = 1140;
			text = "";
			x = 0.25;
			y = 0.19;
			w = 0.50;
			h = 0.04;
			colorBackground[] = { 0, 0, 0, 0.7 };
		};
		class iInstructions : RscText
		{
			idc = 1160;
			text = "Press space to start/stop repair of the selected system";
			x = 0.25;
			y = 0.66;
			w = 0.35;
			h = 0.04;
			sizeEx = 0.028;
			colorText[] = { 1, 1, 1, 1 };
			colorBackground[] = { 0, 0, 0, 0 };
		};
	};

	class controls
	{
		class iSystems : JB_RscListNBox
		{
			idc = 1200;
			x = 0.27;
			y = 0.235;
			w = 0.48;
			h = 0.385;
			columns[] = { 0.0, 0.45, 0.75 };
			onKeyDown = "_this call JBR_RepairSystemsKeyDown;";
		};

		class iFooterBand : RscText
		{
			idc = 1300;
			text = "";
			sizeEx = 0.03;
			x = 0.25;
			y = 0.62;
			w = 0.50;
			h = 0.04;
			colorBackground[] = { 0, 0, 0, 0.7 };
		};

		class iDone : JB_RscButton
		{
			idc = 2000;
			text = "DISMISS";
			x = 0.60;
			y = 0.66;
			w = 0.15;
			h = 0.04;
			action = "[findDisplay 2700, 1] call JBR_RepairDoneAction";
		};
	};
};
