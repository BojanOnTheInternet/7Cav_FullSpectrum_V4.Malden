JB_HF_Requests = []; //[request-string, current-level, target-level, target-time]
JB_HF_Changes = [];

JB_HF_SetLevel =
{
	params ["_key", ["_targetLevel", 1.0, [0]], ["_targetTime", 0.0, [0]]];

	_targetLevel = (_targetLevel max 0.0) min 1.0;

	JB_HF_Changes pushBack [_key, _targetLevel, _targetTime];
};

JB_HF_GetLevel =
{
	params ["_key"];

	//BUG: Needs critical section to be tight
	private _index = JB_HF_Requests findIf { _x select 0 == _key};

	if (_index == -1) exitWith { 1.0 };

	JB_HF_Requests select _index select 1
};

JB_HF_Monitor =
{
	while { true } do
	{
		waitUntil { sleep 0.1; count JB_HF_Changes > 0 };

		private _changes = JB_HF_Changes;
		JB_HF_Changes = [];  //BUG: Needs critical section to be tight

		// Apply the changes to the requests
		{
			_x params ["_key", "_targetLevel", "_targetTime"];

			_targetTime = _targetTime + diag_tickTime;

			private _index = JB_HF_Requests findIf { _x select 0 == _key };
			if (_index == -1) then
			{
				if (_targetLevel != 1.0) then { JB_HF_Requests pushBack [_key, 1.0, _targetLevel, _targetTime] };
			}
			else
			{
				if (_targetLevel == JB_HF_Requests select _index select 1 ) then
				{
					JB_HF_Requests deleteAt _index
				}
				else
				{
					JB_HF_Requests select _index set [2, _targetLevel];
					JB_HF_Requests select _index set [3, _targetTime];
				};
			};
		} forEach _changes;

		private _stepTime = 0.1;
		private _startOfInterval = 0;
		private _endOfInterval = 0;

		private _request = [];
		private _compositeLevel = 0.0;
		private _recalculate = true;

		// Start applying the changes until the sound level stabilizes
		while { _recalculate } do
		{
			_recalculate = false;

			_compositeLevel = 1.0;
			_startOfInterval = diag_tickTime;
			_endOfInterval = diag_tickTime + _stepTime;
			for "_index" from (count JB_HF_Requests - 1) to 0 step -1 do
			{
				_request = JB_HF_Requests select _index;

				_request set [1, linearConversion [_startOfInterval, (_request select 3) max _endOfInterval, _endOfInterval, _request select 1, _request select 2, true]];

				_recalculate = _recalculate || (_request select 1 != _request select 2);
				_compositeLevel = _compositeLevel * (_request select 1);

				if (_request select 1 == 1.0 && _request select 2 == 1.0) then { JB_HF_Requests deleteAt _index };
			};

			_stepTime fadeSound _compositeLevel;
			sleep _stepTime;
		};
	};
};

[] spawn { 	scriptName "JB_HF_Monitor"; _this call JB_HF_Monitor };
