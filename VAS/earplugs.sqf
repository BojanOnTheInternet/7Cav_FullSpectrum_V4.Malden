//    VAS EARPLUGS v2.0   //
//scripts\VAS\Earplugs.sqf//
//      MykeyRM [AW]      //
////////////////////////////

// Pause/Break key toggles earplugs

if (isNil "MEP_KD") then
{
	MEP_KD = (findDisplay 46) displayAddEventHandler ["KeyDown",
		{
			if (_this select 1 == 197) then
			{
				private _fitted = EarplugsFitted;
				switch (_fitted) do
				{
					case true: { EarplugsFitted = false; 2 fadeSound 1; titleText ["Earplugs removed", "plain down", 0.2] };
					case false: { EarplugsFitted = true; 2 fadeSound 0.2; titleText ["Earplugs fitted", "plain down", 0.2];  };
					default { };
				};
			}
		}];

	//sleep 1;

	//_hint1 = "<t color='#ff9d00' size='1.2' shadow='1' shadowColor='#000000' align='center'>** Earplugs Recieved **</t>";   //Item taken hint.
	//_hint2 = "          Use [Pause/Break] key to Insert and Remove";

	//hint parseText (hint1 + hint2);

	EarplugsFitted = false;
}