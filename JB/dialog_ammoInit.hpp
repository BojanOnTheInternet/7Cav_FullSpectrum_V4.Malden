class JBA_Transfer
{
	idd = 2700;
	movingEnable = false;
	moving = 1;
	onUnload = "_this call JBA_TransferUnload";

	class controlsBackground
	{
		class iTitle : RscText
		{
			idc = 1100;
			text = "AMMUNITION TRANSFER";
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
		class iFromBand : RscText
		{
			idc = 1140;
			text = "";
			x = 0.00;
			y = 0.04;
			w = 1.00;
			h = 0.04;
			colorBackground[] = { 0, 0, 0, 0.7 };
		};
		class iToBand : RscText
		{
			idc = 1150;
			text = "";
			x = 0.00;
			y = 0.48;
			w = 1.00;
			h = 0.04;
			colorBackground[] = { 0, 0, 0, 0.7 };
		};
		class iInstructions : RscText
		{
			idc = 1160;
			text = "Press space to transfer the selected ammunition";
			x = 0.00;
			y = 0.96;
			w = 0.90;
			h = 0.04;
			sizeEx = 0.028;
			colorText[] = { 1, 1, 1, 1 };
			colorBackground[] = { 0, 0, 0, 0 };
		};
	};

	class controls
	{
		class iFrom : JB_RscListNBox
		{
			idc = 1200;
			x = 0.02;
			y = 0.085;
			w = 0.98;
			h = 0.39;
			columns[] = { 0.0, 0.1, 0.75 };
			onKeyDown = "_this call JBA_TransferFromKeyDown;";
		};

		class iTo : JB_RscListNBox
		{
			idc = 1500;
			x = 0.02;
			y = 0.525;
			w = 0.98;
			h = 0.39;
			columns[] = { 0.0, 0.1, 0.75 };
			onKeyDown = "_this call JBA_TransferToKeyDown;";
		};

		class iFromStore : RscText
		{
			idc = 1700;
			text = "XXX";
			x = 0.00;
			y = 0.04;
			w = 0.44;
			h = 0.04;
		};

		class iFromCapacity : JB_RscProgress
		{
			idc = 1800;
			x = 0.60;
			y = 0.04;
			w = 0.40;
			h = 0.04;
		};

		class iToStore : JB_RscCombo
		{
			idc = 1600;
			x = 0.00;
			y = 0.48;
			w = 0.44;
			h = 0.04;
		};

		class iToCapacity : JB_RscProgress
		{
			idc = 1900;
			x = 0.60;
			y = 0.48;
			w = 0.40;
			h = 0.04;
		};

		class iDone : JB_RscButton
		{
			idc = 2000;
			text = "DISMISS";
			x = 0.85;
			y = 0.96;
			w = 0.15;
			h = 0.04;
			action = "[findDisplay 2700, 1] call JBA_TransferDoneAction";
		};
	};
};