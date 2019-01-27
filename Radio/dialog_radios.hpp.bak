class Radio_Radios
{
	idd = 3300;
	movingEnabled = true;

	onUnload = "_this call Radio_Custom_Unload";
};

class Radio_Radio : RscPictureKeepAspect
{
	idc = 1001;
	text = "Radio\Radio.paa";
	x = "safeZoneX + safeZoneW - 0.3";
	y = "safeZoneY + safeZoneH - 0.72";
	w = 0.7;
	h = 0.7;
	colorText[] = { 1, 1, 1, 1 };
	moving = 1;
};

class Radio_ColorBand : RscPicture
{
	idc = 1002;
	x = "safeZoneX + safeZoneW - 0.175";
	y = "safeZoneY + safeZoneH - 0.139";
	w = 0.105;
	h = 0.01;
};

class Radio_ChannelBackground : RscPicture
{
	idc = 1004;
	text = "#(argb,8,8,3)color(0.75,1.0,0.47,1)";
	x = "safeZoneX + safeZoneW - 0.175";
	y = "safeZoneY + safeZoneH - 0.189";
	w = 0.105;
	h = 0.04;
};

class Radio_ChannelText : RscText
{
	idc = 1102;
	x = "safeZoneX + safeZoneW - 0.18";
	y = "safeZoneY + safeZoneH - 0.18";
	w = 0.1;
	h = 0.025;

	text = "CHANNEL 1";
	font = "LCD14";
	sizeEx = 0.025;
	shadow = 0;
	colorText[] = { 0, 0, 0, 1 };
};

class Radio_SimpleButton : RscButton
{
	colorText[] = { 0, 0, 0, 1 };
	colorDisabled[] = { 0.4, 0.4, 0.4, 1 };
	colorBackground[] = { 0, 0, 0, 0 };
	colorBackgroundDisabled[] = { 0, 0, 0, 0 };
	colorBackgroundActive[] = { 0, 0, 0, 0 };
	colorFocused[] = { 0, 0, 0, 0 };
	colorShadow[] = { 0, 0, 0, 0 };
	colorBorder[] = { 0, 0, 0, 0 };
	soundEnter[] = { "\A3\ui_f\data\sound\onover", 0.09, 1 };
	soundPush[] = { "\A3\ui_f\data\sound\new1", 0, 0 };
	soundClick[] = { "\A3\ui_f\data\sound\onclick", 0.07, 1 };
	soundEscape[] = { "\A3\ui_f\data\sound\onescape", 0.09, 1 };
	style = ST_CENTER;
	x = 0;
	y = 0;
	w = 0.025;
	h = 0.025;
	shadow = 0;
	font = "LCD14";
	sizeEx = "0.02";
	offsetX = 0.0;
	offsetY = 0.0;
	offsetPressedX = 0.0;
	offsetPressedY = 0.0;
	borderSize = 0;

	onMouseButtonDown = "_this call Radio_Custom_ChannelClick; false";
};

class Radio_ChannelNext : Radio_SimpleButton
{
	idc = 1103;
	x = "safeZoneX + safeZoneW - 0.09";
	y = "safeZoneY + safeZoneH - 0.1925";
	text = "+";
};

class Radio_ChannelPrev : Radio_SimpleButton
{
	idc = 1104;
	x = "safeZoneX + safeZoneW - 0.09";
	y = "safeZoneY + safeZoneH - 0.1675";
	text = "-";
};

class Radio_NameText : RscEdit
{
	idc = 1105;
	x = "safeZoneX + safeZoneW - 0.18";
	y = "safeZoneY + safeZoneH - 0.10";
	w = 0.120;
	h = 0.025;

	colorBackground[] = { 0, 0, 0, 0 };
	colorBorder[] = { 0, 0, 0, 0 };
	style = ST_CENTER + ST_NO_RECT;
	sizeEx = 0.025;
	shadow = 0;
	borderSize = 0;
};