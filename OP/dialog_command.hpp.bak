class iHostButton : JB_RscButton
{
	x = 0.01;
	y = 0.495;
	w = 0.15;
	h = 0.05;
	text = "SERVER";
	colorText[] = { 0, 1, 0, 1 };
	onMouseButtonClick = "_this call OP_Command_SelectHost";
};

class OP_Command
{
	idd = 3200;
	movingEnable = false;
	moving = 1;
	onLoad = "";
	onUnload = "[] call OP_Command_Unload";

	class controlsBackground
	{
		class iTitle : RscText
		{
			idc = 1100;
			text = "COMMAND";
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
	};

	class controls
	{
		class iCommand : RscEdit
		{
			idc = 1200;
			x = 0.01;
			y = 0.045;
			w = 0.98;
			h = 0.50;
			style = 0x10;
			sizeEx = 0.03;
		};

		class iOutput : RscText
		{
			idc = 1300;
			x = 0.01;
			y = 0.545;
			w = 0.98;
			h = 0.3;
			style = 0x10;
			sizeEx = 0.03;
		};

		class iExecute : JB_RscButton
		{
			idc = 1700;
			text = "EXECUTE";
			x = 0.70;
			y = 0.96;
			w = 0.15;
			h = 0.04;
			action = "[findDisplay 3200] call OP_Command_ExecuteAction";
		};

		class iDone : JB_RscButton
		{
			idc = 2000;
			text = "DISMISS";
			x = 0.85;
			y = 0.96;
			w = 0.15;
			h = 0.04;
			action = "[findDisplay 3200] call OP_Command_DoneAction";
		};
	};
};