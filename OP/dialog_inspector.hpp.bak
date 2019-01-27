class OP_Inspector
{
	idd = 3100;
	movingEnable = false;
	moving = 1;

	class controlsBackground
	{
		class iTitle : RscText
		{
			idc = 1100;
			text = "INSPECTOR";
			x = 0.00;
			y = 0.00;
			w = 1.00;
			h = 0.04;
			colorBackground[] = { "(profilenamespace getvariable ['GUI_BCG_RGB_R',0.3843])", "(profilenamespace getvariable ['GUI_BCG_RGB_G',0.7019])", "(profilenamespace getvariable ['GUI_BCG_RGB_B',0.8862])", "(profilenamespace getvariable ['GUI_BCG_RGB_A',0.7])" };
		};
		class iBackground : RscText
		{
			idc = 1130;
			text = "";
			x = 0.00;
			y = 0.04;
			w = 1.00;
			h = 0.92;
			colorBackground[] = { 0, 0, 0, 0.7 };
		};
		class iStrongpointsBand : RscText
		{
			idc = 1140;
			text = "Strongpoints";
			x = 0.00;
			y = 0.04;
			w = 1.00;
			h = 0.04;
			colorBackground[] = { 0, 0, 0, 0.7 };
		};
		class iDetailsBand : RscText
		{
			idc = 1150;
			text = "Details";
			x = 0.00;
			y = 0.28;
			w = 1.00;
			h = 0.04;
			colorBackground[] = { 0, 0, 0, 0.7 };
		};
		class iInstructions : RscText
		{
			idc = 1160;
			text = "";
			x = 0.00;
			y = 0.96;
			w = 0.70;
			h = 0.04;
			sizeEx = 0.028;
			colorText[] = { 1, 1, 1, 1 };
			colorBackground[] = { 0, 0, 0, 0 };
		};
	};

	class controls
	{
		class iStrongpoints : JB_RscListNBox
		{
			idc = 1200;
			x = 0.02;
			y = 0.085;
			w = 0.98;
			h = 0.19;
			columns[] = { 0.0 };
			onKeyDown = "_this call OP_Inspector_StrongpointsKeyDown;";
		};

		class iDetails : JB_RscListNBox
		{
			idc = 1500;
			x = 0.02;
			y = 0.325;
			w = 0.98;
			h = 0.59;
			columns[] = { 0.0, 0.3, 0.75 };
			onKeyDown = "_this call OP_Inspector_DetailsKeyDown;";
		};

		class iPauseResume : JB_RscButton
		{
			idc = 1700;
			text = "PAUSE";
			x = 0.70;
			y = 0.96;
			w = 0.15;
			h = 0.04;
			action = "[findDisplay 3100] call OP_Inspector_PauseResumeAction";
		};

		class iDone : JB_RscButton
		{
			idc = 2000;
			text = "DISMISS";
			x = 0.85;
			y = 0.96;
			w = 0.15;
			h = 0.04;
			action = "[findDisplay 3100] call OP_Inspector_DoneAction";
		};
	};
};