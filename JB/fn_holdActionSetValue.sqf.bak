params ["_index", "_value"];

if (count JB_HA_CurrentAction == 0) exitWith { false };

switch (_index) do
{
	case JB_HA_LABEL: { JB_HA_CurrentAction set [JB_HA_LABEL, _value]; true };
	case JB_HA_FOREGROUND_ICON: { JB_HA_CurrentAction set [JB_HA_FOREGROUND_ICON_SETVALUE, _value]; true };
	case JB_HA_FOREGROUND_ICON_SCALE: { JB_HA_CurrentAction set [JB_HA_FOREGROUND_ICON_SCALE_SETVALUE, _value]; true };
	default { false }
};