/*
Cluster: [position, index, units, radius]
*/

private _units = _this select 0;
private _maximumClusters = _this select 1;

private _min = [1e30, 1e30, 1e30];
private _max = [-1e30, -1e30, -1e30];
{
	private _position = getPos _x;
	_min set [0, (_min select 0) min (_position select 0)];
	_min set [1, (_min select 1) min (_position select 1)];
	_min set [2, (_min select 2) min (_position select 2)];
	_max set [0, (_max select 0) max (_position select 0)];
	_max set [1, (_max select 1) max (_position select 1)];
	_max set [2, (_max select 2) max (_position select 2)];
} forEach _units;

private _size = [(_max select 0) - (_min select 0), (_max select 1) - (_min select 1), (_max select 2) - (_min select 2)];

private _clusters = [];
for "_i" from 1 to _maximumClusters do
{
	private _randomPosition = _min vectorAdd [random (_size select 0), random (_size select 1), random (_size select 2)];
	_clusters pushBack [_randomPosition, _i, 0, 0];
};

private _unitPositions = [];
{
	_unitPositions pushBack [getPos _x, -1];
} forEach _units;

for "_i" from 1 to 30 do
{
	private _changed = false;
	private _cluster = [];
	private _unit = [];
	private _closestCluster = -1;
	private _closestDistance = 0;
	private _distance = 0;
	{
		_unit = _x;
		_closestDistance = 1e30;
		_closestCluster = [];
		{
			_cluster = _x;
			_distance = (_unit select 0) distanceSqr (_cluster select 0);
			if (_distance < _closestDistance) then
			{
				_closestDistance = _distance;
				_closestCluster = _cluster;
			};
		} forEach _clusters;
		if (_unit select 1 != _closestCluster select 1) then
		{
			_unit set [1, _closestCluster select 1];
			_changed = true;
		};
	} forEach _unitPositions;

	if (not _changed) exitWith { };

	{
		_cluster = _x;
		private _unitsInCluster = 0;
		private _accumulator = [0,0,0];
		{
			_unit = _x;
			if (_unit select 1 == _cluster select 1) then
			{
				_accumulator = _accumulator vectorAdd (_unit select 0);
				_unitsInCluster = _unitsInCluster + 1;
			};
		} forEach _unitPositions;
		if (_unitsInCluster > 0) then
		{
			_cluster set [0, _accumulator vectorMultiply (1 / _unitsInCluster)];
		};
		_cluster set [2, _unitsInCluster];
	} forEach _clusters;
};

_clusters = _clusters select { (_x select 2) > 0 };

private _cluster = [];
private _unitsInCluster = [];
private _maxDistance = 0;
{
	_cluster = _x;

	_unitsInCluster = [];
	_maxDistance = 0;
	{
		if (_x select 1 == _cluster select 1) then
		{
			_unitsInCluster pushBack (_units select _forEachIndex);
			_maxDistance = _maxDistance max ((_x select 0) distanceSqr (_cluster select 0));
		};
	} forEach _unitPositions;

	_cluster set [2, _unitsInCluster];
	_cluster set [3, (sqrt _maxDistance) max 1.0]; // Max 1.0 defends against case where a vehicle crew or passengers constitutes the entire cluster and they have the same position
} forEach _clusters;

_clusters