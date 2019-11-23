private _showTips =
{
	[0.8, 0.6, parseText loadFile "media\text\billboard-tips.txt"] call Billboard_ShowMessage;
};

(_this select 0) setObjectTextureGlobal [0, "media\images\7cavflag.jpg"];
(_this select 0) addAction ["Tips", _showTips, nil, 10, true, true];