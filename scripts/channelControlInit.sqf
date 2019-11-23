#define CHANNEL_NONE -1
#define CHANNEL_GLOBAL 0
#define CHANNEL_SIDE 1
#define CHANNEL_COMMAND 2
#define CHANNEL_GROUP 3
#define CHANNEL_VEHICLE 4
#define CHANNEL_DIRECT 5
#define CHANNEL_CUSTOM1 6
#define CHANNEL_CUSTOM2 7
#define CHANNEL_CUSTOM3 8
#define CHANNEL_CUSTOM4 9
#define CHANNEL_CUSTOM5 10
#define CHANNEL_CUSTOM6 11
#define CHANNEL_CUSTOM7 12
#define CHANNEL_CUSTOM8 13
#define CHANNEL_CUSTOM9 14
#define CHANNEL_CUSTOM10 15

CHANNEL_GLOBAL enableChannel false;
CHANNEL_SIDE enableChannel [true, false];
CHANNEL_COMMAND enableChannel [true, true];

setCurrentChannel CHANNEL_GROUP;

[] spawn
{
	scriptName "ChannelControlInit";

	while { true } do
	{
		sleep 1;

		if (not isNull player) then
		{
			[CHANNEL_GLOBAL, not isNull getAssignedCuratorLogic player] call Radio_EnableChannel;
			[CHANNEL_VEHICLE, vehicle player != player] call Radio_EnableChannel;
		};
	};
};
