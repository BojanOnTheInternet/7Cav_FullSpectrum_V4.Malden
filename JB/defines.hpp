class JB_RscListNBox
{
	access = 0;
	type = CT_LISTNBOX;// 102; 
	style = ST_MULTI;
	font = "PuristaMedium";
	sizeEx = 0.028;
	colorText[] = { 1, 1, 1, 1 };
	colorBackground[] = { 0, 0, 0, 0.7 };
	/*
	** type specific
	*/
	autoScrollSpeed = -1;
	autoScrollDelay = 5;
	autoScrollRewind = 0;
	arrowEmpty = "#(argb,8,8,3)color(1,1,1,1)";
	arrowFull = "#(argb,8,8,3)color(1,1,1,1)";
	color[] = { 1, 1, 1, 1 };
	colorScrollbar[] = { 0.95, 0.95, 0.95, 1 };
	colorSelect[] = { 0, 0, 0, 0.7 };
	colorSelectBackground[] = { 1, 1, 1, 0.7 };
	colorSelect2[] = { 0, 0, 0, 1 };
	colorSelectBackground2[] = { 1, 1, 1, 1 };
	colorDisabled[] = { 1,1,1,0.2 };
	drawSideArrows = 0;
	idcLeft = -1;
	idcRight = -1;
	maxHistoryDelay = 1;
	rowHeight = 0;
	soundSelect[] = { "", 0.1, 1 };
	period = -1;
	shadow = 0;

	class ListScrollBar
	{
		arrowEmpty = "\A3\ui_f\data\gui\cfg\scrollbar\arrowEmpty_ca.paa";
		arrowFull = "\A3\ui_f\data\gui\cfg\scrollbar\arrowFull_ca.paa";
		border = "\A3\ui_f\data\gui\cfg\scrollbar\border_ca.paa";
		thumb = "\A3\ui_f\data\gui\cfg\scrollbar\thumb_ca.paa";
		color[] = { 1,1,1,0.6 };
		colorActive[] = { 1,1,1,1 };
		colorDisabled[] = { 1,1,1,0.2 };
	};
};

class JB_RscCombo
{
	access = 0;
	type = CT_COMBO;
	style = ST_LEFT;
	colorText[] = { 1, 1, 1, 1 };
	colorScrollbar[] = { 1, 1, 1, 1 };
	colorSelect[] = { 0, 0, 0, 0.7 };
	colorSelectBackground[] = { 1, 1, 1, 0.7 };
	colorSelect2[] = { 0, 0, 0, 1 };
	colorSelectBackground2[] = { 1, 1, 1, 1 };
	colorBackground[] = { 0, 0, 0, 0.7 };
	colorDisabled[] = { 1, 1, 1, 0.2 };
	arrowFull = "\A3\ui_f\data\gui\rsccommon\rsccombo\arrow_combo_active_ca.paa";
	arrowEmpty = "\A3\ui_f\data\gui\rsccommon\rsccombo\arrow_combo_ca.paa";
	font = "PuristaMedium";
	sizeEx = 0.04;
	rowHeight = 0.04;
	wholeHeight = 4 * 0.04;
	soundSelect[] = { "", 0.1, 1 };
	soundExpand[] = { "", 0.1, 1 };
	soundCollapse[] = { "", 0.1, 1 };
	maxHistoryDelay = 1.0;
	period = -1;
	shadow = 0;

	class ComboScrollBar
	{
		color[] = { 1, 1, 1, 0.6 };
		colorActive[] = { 1, 1, 1, 1 };
		arrowEmpty = "\A3\ui_f\data\gui\cfg\scrollbar\arrowEmpty_ca.paa";
		arrowFull = "\A3\ui_f\data\gui\cfg\scrollbar\arrowFull_ca.paa";
		border = "\A3\ui_f\data\gui\cfg\scrollbar\border_ca.paa";
		shadow = 0;
	};
};

class JB_RscProgress
{
	type = 8;
	style = 0;
	colorFrame[] = { 0, 0, 0, 0.7 };
	colorBar[] = { 1, 1, 1, 1 };
	texture = "#(argb,8,8,3)color(1,1,1,1)";
};

class JB_RscButton
{
	access = 0;
	type = CT_BUTTON;
	style = ST_CENTER;
	font = "PuristaMedium";
	sizeEx = 0.04;
	colorText[] = { 1, 1, 1, 1 };
	colorBackground[] = { 0, 0, 0, 1 };
	colorBackgroundActive[] = { 0.5, 0.5, 0.5, 1 };
	colorDisabled[] = { 0.3, 0.3, 0.3, 1 };
	colorBackgroundDisabled[] = { 0.6, 0.6, 0.6, 1 };
	offsetX = 0;
	offsetY = 0;
	offsetPressedX = 0;
	offsetPressedY = 0;
	colorFocused[] = { 0, 0, 0, 1 };
	shadow = 0;
	colorShadow[] = { 0, 0, 0, 1 };
	borderSize = 0;
	colorBorder[] = { 1, 1, 1, 1 };
	soundEnter[] = { "", 0.1, 1 };
	soundPush[] = { "", 0.1, 1 };
	soundClick[] = { "", 0.1, 1 };
	soundEscape[] = { "", 0.1, 1 };
};