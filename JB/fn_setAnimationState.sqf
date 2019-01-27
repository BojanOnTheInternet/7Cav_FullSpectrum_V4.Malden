private _animationState = param [0, "", [""]];
private _key = param [1, "", [""]];
private _value = param [2, "", [""]];

switch (toLower _key) do
{
	case "a": { (_animationState select [0, 1]) + _value + (_animationState select [4]) };
	case "p": { (_animationState select [0, 5]) + _value + (_animationState select [8]) };
	case "m": { (_animationState select [0, 9]) + _value + (_animationState select [12]) };
	case "s": { (_animationState select [0, 13]) + _value + (_animationState select [16]) };
	case "w": { (_animationState select [0, 17]) + _value + (_animationState select [20]) };
	case "d": { (_animationState select [0, 21]) + _value + (_animationState select [24]) };
};