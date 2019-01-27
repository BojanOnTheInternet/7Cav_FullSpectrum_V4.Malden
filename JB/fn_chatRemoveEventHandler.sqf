private _chatHandler = param [0, {}, [{}]];

if (isNil "JB_CHAT_Handlers") exitWith {};

JB_CHAT_Handlers = JB_CHAT_Handlers - [_chatHandler];

if (count JB_CHAT_Handlers == 0) then
{
	JB_CHAT_Handlers = nil;
};