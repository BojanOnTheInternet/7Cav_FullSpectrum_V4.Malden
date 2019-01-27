JB_DP_HandleDamage =
{
	params ["_object", "_selection", "_damage", "_source", "_projectile", "_partIndex", "_instigator"];

	private _data = _object getVariable "JB_DP_Data";

	private _finalDamage = _damage;

	if (_this call (_data select 2)) then
	{
		private _currentDamage = if (_partIndex == -1) then { damage _object } else { _object getHitIndex _partIndex };
		private _pulse = _damage - _currentDamage;

		_finalDamage = _currentDamage;

		if (_pulse > _data select 0) then { _finalDamage = _currentDamage + (_pulse * (_data select 1)) };
	};

	_finalDamage
};
