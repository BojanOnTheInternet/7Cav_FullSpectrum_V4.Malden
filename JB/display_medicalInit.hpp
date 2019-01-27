class JBM_MedicMonitor
{
	idd = 2600;
	fadeout = 0;
	fadein = 0;
	duration = 1e30;
	onLoad = "uiNamespace setVariable ['JBM_MedicMonitor', _this select 0]";

	class controls
	{
		class iMainFrame : RscText
		{
			idc = 1000;
			x = 0.1;
			y = 0.3;
			w = 0.8;
			h = 0.2;
			colorBackground[] = { 0, 0, 0, 0.7 };
		};
		class iTitle : RscText
		{
			idc = 1100;
			text = "MEDICS";
			x = 0.1;
			y = 0.26;
			w = 0.8;
			h = 0.04;
			colorBackground[] = { "(profilenamespace getvariable ['GUI_BCG_RGB_R',0.3843])", "(profilenamespace getvariable ['GUI_BCG_RGB_G',0.7019])", "(profilenamespace getvariable ['GUI_BCG_RGB_B',0.8862])", "(profilenamespace getvariable ['GUI_BCG_RGB_A',0.7])" };
		};
		class iMedicList : JB_RscListNBox
		{
			idc = 1200;
			x = 0.1;
			y = 0.32;
			w = 0.8;
			h = 0.18;
			colorBackground[] = { 0.0, 0.0, 0.0, 0 };
			columns[] = { 0.0, 0.6, 0.75 };
		};
		class iAdditionalInformation : RscText
		{
			idc = 1300;
			text = "";
			x = 0.1;
			y = 0.5;
			w = 0.7;
			h = 0.04;
			colorBackground[] = { 0, 0, 0, 0.7 };
			sizeEx = 0.03;
		};
		class iBleedoutCountdown : RscText
		{
			idc = 1400;
			text = "";
			x = 0.8;
			y = 0.5;
			w = 0.1;
			h = 0.04;
			colorBackground[] = { 0, 0, 0, 0.7 };
			sizeEx = 0.03;
		};
	};
};