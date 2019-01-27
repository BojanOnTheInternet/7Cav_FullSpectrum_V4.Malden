params ["_extractionCallback", "_extractionPassthrough"];

if (not isNil "_extractionCallback") then { player setVariable ["JB_SR_ExtractionCallback", [_extractionCallback, if (isNil "_extractionPassthrough") then { nil } else { _extractionPassthrough }]] };

JB_SR_AddActions =
{
	player addAction ["Search rubble", { _this call JB_SR_SearchRubbleHoldAction }, nil, 10, true, true, "", "[] call JB_SR_SearchRubbleCondition"];
};

call JB_SR_AddActions;
player addEventHandler ["Respawn", { call JB_SR_AddActions }];