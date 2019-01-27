params ["_index"];

if (count JB_HA_CurrentAction == 0) exitWith {};

switch (_index) do
{
	case JB_HA_KEYS;
	case JB_HA_LABEL;
	case JB_HA_DURATION;
	case JB_HA_INTERVAL;
	case JB_HA_CALLBACK;
	case JB_HA_PASSTHROUGH;
	case JB_HA_START_TIME;
	case JB_HA_PROGRESS_STEP;
	case JB_HA_INTERVAL_STEP;
	case JB_HA_STATE;
	case JB_HA_FOREGROUND_ICON: { JB_HA_CurrentAction select _index };

	default {}
};