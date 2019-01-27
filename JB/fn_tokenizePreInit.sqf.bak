JB_Tokenizer_Alphabetic = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
JB_Tokenizer_Numeric = "0123456789";
JB_Tokenizer_Alphanumeric = JB_Tokenizer_Alphabetic + JB_Tokenizer_Numeric;
JB_Tokenizer_IdentifierLead = "_" + JB_Tokenizer_Alphabetic;
JB_Tokenizer_IdentifierContinued = "_" + JB_Tokenizer_Numeric + JB_Tokenizer_Alphabetic;
JB_Tokenizer_Number = "." + JB_TokenizerNumeric;
JB_Tokenizer_Quotes = """'";
JB_Tokenizer_Symbols = "!@#$%^&*()_-+={[}]|\:;<,>?/";
JB_Tokenizer_CompoundSymbols = [">=", "<=", "//", "/*", "*/"];

JB_Tokenizer_TokenError = -1;
JB_Tokenizer_TokenIdentifier = 1;
JB_Tokenizer_TokenNumber = 2;
JB_Tokenizer_TokenQuotedString = 3;
JB_Tokenizer_TokenSymbol = 4;

JB_Tokenize_Identifier =
{
	params ["_characters"];

	private _identifier = [_characters deleteAt 0];
	while { count _characters > 0 && { JB_Tokenizer_IdentifierContinued find (_characters select 0) >= 0 } } do
	{
		_identifier pushBack (_characters deleteAt 0);
	};

	[JB_Tokenizer_TokenIdentifier, _identifier joinString ""]
};

JB_Tokenize_Number =
{
	params ["_characters"];

	private _number = [_characters deleteAt 0];
	while { count _characters > 0 && { JB_Tokenizer_Number find (_characters select 0) >= 0 } } do
	{
		_number pushBack (_characters deleteAt 0);
	};

	[JB_Tokenizer_TokenNumber, parseNumber (_number joinString "")]
};

JB_Tokenize_Symbol =
{
	params ["_characters"];

	private _symbol = (_characters deleteAt 0);
	if (count _characters > 0) then
	{
		private _compoundSymbol = _symbol + (_characters select 0);
		if (_compoundSymbol in JB_Tokenizer_CompoundSymbols) then
		{
			_symbol = _symbol + (_characters deleteAt 0);
		};
	};

	[JB_Tokenizer_TokenSymbol, _symbol]
};

JB_Tokenize_QuotedString =
{
	params ["_characters"];

	private _quote = _characters deleteAt 0;

	private _string = [];
	private _endOfString = false;

	while { count _characters > 0 && not _endOfString } do
	{
		_character = _characters select 0;
		
		if (_characters select 0 != _quote) then
		{
			_string pushBack (_characters deleteAt 0);
		}
		else
		{
			_characters deleteAt 0;
			_endOfString = true;

			if (count _characters > 0 && (_characters select 0) == _quote) then
			{
				_endOfString = false;
				_string pushBack (_characters deleteAt 0);
			}
		}
	};

	if (not _endOfString) exitWith { [JB_Tokenizer_TokenError, "quoted string not closed"] };

	[JB_Tokenizer_TokenQuotedString, _string joinString ""]
};

JB_TokenizeString =
{
	params ["_string"];

	private _tokens = [];
	private _characters = _string splitString "";

	while { count _characters > 0 } do
	{
		if ((_characters select 0) == " ") then
		{
			_characters deleteAt 0;
		}
		else
		{
			if (JB_Tokenizer_IdentifierLead find (_characters select 0) >= 0) then
			{
				_tokens pushBack ([_characters] call JB_Tokenize_Identifier);
			}
			else
			{
				if (JB_Tokenizer_Numeric find (_characters select 0) >= 0) then
				{
					_tokens pushBack ([_characters] call JB_Tokenize_Number);
				}
				else
				{
					if (JB_Tokenizer_Quotes find (_characters select 0) >= 0) then
					{
						_tokens pushBack ([_characters] call JB_Tokenize_QuotedString);
					}
					else
					{
						if (JB_Tokenizer_Symbols find (_characters select 0) >= 0) then
						{
							_tokens pushBack ([_characters] call JB_Tokenize_Symbol);
						}
						else
						{
							_characters deleteAt 0;
							_tokens pushBack [JB_Tokenizer_TokenError, "unexpected character"];
						}
					}
				}
			}
		};
	};

	_tokens
};