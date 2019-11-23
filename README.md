7Cav Full Spectrum v4.2.2 changelog:

Changed:
- Typos in various places
- Woodland camo has been swapped for desert camo on all vehicles
- Anybody can now enter Apollo/Mustang vehicles in all positions, except driver
- The surrender threshold has been increased. Hopefully this means less looking for a handful of AI in a large city
- Removed canister rounds from MK19 HMMWV
- Mustang's vehicles now count as medical vehicles after they respawn
- Base logistics vehicles have had their spare wheels/tracks removed
- ACE Cargo capacity for vehicles has been upped on some things
- Enemy transport helicopters should spawn further out
- Reduced number of support slots. Now we have 2 transport rotory, 2 attack rotory, 1 eagle, 1 air logistics (Titan)
- Transport rotory pilots can now fly all transport rotory aircraft
- Attack rotory pilots can now fly all attack rotory aircraft
- Titan-1 is now the air logistics unit and can fly the V44 and vehicle transport chinook (vanilla version)
- Logistics vehicles should no longer despawn if abandoned (although they will be marked to avoid being lost)
- Concrete hedgehogs removed from fortify, replaced with concrete barrier
- Apollo CP Box truck replaced with another type of SOV
- Apollo CP SOV truck can be loaded into the V44 and slung by Titan-1 Chinook
- C130 removed since, lets be honest, nobody was using it. Available to be spawned by Zeus
- Disabled script that fixed broken buildings throughout the map
- Countermeasures deployed on base no longer trigger a "Do not fire on base" message

Added:
- Infantry transport Chinook (RHS version)
- Vehicle transport Chinook (Vanilla version)
- Vehicle Chinook should be able to transport all Apollo vehicles
- Static Stinger AA launcher for use by Apollo
- "Rain rain go away" script. Hopefully no more random showers!
- 1x MRZR for the awesome longshot dudes
- Server should restart at 0900z and 2100z (times subject to change)
- 155mm self-propelled gun for Apollo
- Map rotation timer. By default, maps will rotate after 6 hours and once the current AO ends. If players want to stay on the map, Zeus can use a command to extend the timer
- Zeus commands are now listed under the "Gamemaster" tab on the map (only visible when in Zeus slot)
- Heavy lift area for Titan-1
- TANOA!

------

7Cav Full Spectrum v4.2.1 changelog:

Fixed:
- There should be less enemy armour spawning in, and they should spawn in less frequently.
- Apollo and Mustang can now enter and drive each other's vehicles
- Apollo members should be able to drive in the same vehicle together
- Removed all of JB's radio stuff from Tac1 - this might help with radio issues on Tac2
- The "abandonment" distance and time thresholds have been increased for land vehicles to 1.5km and 10 minutes (no players in that area for that time)
- Logistics vehicles have a large ACE cargo capacity
- Spare wheels and tracks added to logistic repair vehicles
- FOB fortifications require you to be near the FOB CP vehicle (100m)
- FOB fortifications require you be an Apollo unit.
- Fixed bug with fortifications allowing any player to enter any vehicle
- Fixed bug with splinting where option would not always appear for players (hopefully)
- Fixed bug with splinting where taking any damage would cause your splints to "fall off"
- Fixed a way players could bypass the vehicle restrictions
- Changed the VTOL type that is spawned from infantry to vehicle
- You can no longer load the Bradley into the logistics vehicles (lol)
- Cut down the mission file size by a few MB by removing extra files
- Lowered the max amount of AI from 225 to 150. This will hopefully help with the poor frame rate when we get to a busy server

Added:
- Repair logi truck now has limited fuel and ammo resupply points (half of what the regular trucks have)
- Transport VTOL can now hold the Bradley through ACE Cargo
- Ammo box spawner is now part of the arsenal boxes near the vehicle depot. Apollo members can load these up and put them into the larger cargo of their vehicles.
- Zeus now has access to "mp" and "gm" commands
- Zeus has a new command "gm fortify points <amount>" to add/remove budget from Apollo
- Added helipad to the fortify list
- Added concrete hedgehogs to the fortify list
- Added grass cutter to the fortify list
- Removed helipad lights + bar gate from the list