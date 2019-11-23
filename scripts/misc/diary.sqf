if (!hasInterface) exitWith {};

waitUntil {!isNull player};

#define BRIEFING
#ifdef BRIEFING
player createDiaryRecord ["diary", ["Advances",
"
An advance involves assaults on a series of locations on the island.  The current operation is indicated on the map by a 'crossed swords' task icon.  The map's 'Tasks' tab will
list the objectives of the current operation.  There are three types of operations in an advance; an attack on bivouacked (camped) forces, an attack on entrenched forces, and a defense.  In
each case, the CSAT forces contain infantry plus light armor.  If players are operating armor or aircraft near the operational area, the CSAT forces will send their own amor or
aircraft to meet the threat.  Note that armor and aircraft will continue to be sent at intervals regardless of the progress of the player infantry.<br/>
<br/>
<font size='16'>Bivouacked forces</font>
<br/>
The only objective of the operation is to defeat the camped enemy, forcing their surrender.<br/>
<br/>
<font size='16'>Entrenched forces</font>
<br/>
There are two objectives to these operations: 1) to destroy the communications center and 2) to hold the area indicated on the map by a red ring.  That area will initially be held
by enemy infantry supported by light armored vehicles and possibly a mortar.  Heavy armor may patrol outside.  Anti-vehicle mine fields will be encountered at points around the red
ring.  There may be additional objectives in an operation, so be sure to check the Tasks tab on the map for the complete list in any given operation.
<br/>
<br/>
The enemy infantry has a headquarters unit which communicates with a reserve force.  As soon as the players begin to engage the CSAT garrison that headquarters unit will start
requesting mobilization of the reserve, and that process will continue until either the headquarters unit's communications gear (a satellite phone) is disabled or the entire
reserve force has completed mobilization.  Mobilization of all reinforcements will be completed within 3-8 minutes.  Knocking out the communications gear (with a grenade or other
explosives) prevents additional mobilization, but will not prevent forces which have already been mobilized from arriving to reinforce the garrison.<br/>
<br/>
If the enemy garrison is significantly reduced in force, mobilized reinforcements will arrive in an attempt to restore it to full strength.  This can happen multiple times,
with reinforcements arriving by air, by land, and, where possible, by sea.  Once reinforcements start arriving, the players must maintain an infantry presence inside the red ring.
If players fail to do so, the operation will be recorded as a NATO defeat for not having held the marked area.  If the players can hold their position until all reinforcements
have been committed and the players maintain a 3:1 numerical advantage, the operation will be recorded as a NATO victory.  At the end of an operation, the flag at the CSAT headquarters
will show a CSAT flag for a NATO defeat and a NATO flag for a NATO victory.<br/>
<br/>
Note that incapacitated and mounted infantry are not considered to be part of the forces 'holding the operational area'.  Also, it is possible for infantry outside the red ring to
influence control of the area, but the farther a soldier is from the edge of the red ring, the less influence he provides.  In general, it is best to stay within the contested area.<br/>
<br/>
<font size='16'>Defense</font>
<br/>
Once an entrenched force has been successfully defeated and victory has been declared, it is possible that CSAT will counterattack in an effort to take back that same location.  Essentially, the roles
of a NATO assault on an entrenched CSAT force are reversed; the area is marked with a blue ring and the players are expected to defend that area against the CSAT assault.  As with reinforcements,
the assault will arrive by air, by land, and where practical, by sea.  Hold the area against those forces.
"
]];

player createDiaryRecord ["diary", ["Unit callsigns",
"
<br/><font face='TahomaB' size='12'>Personnel</font>
<br/>
<font face='EtelkaMonospacePro' size='10'>
<br/>JTAC                           Infidel
<br/>Logistics/FOB Ops              Apollo
<br/>Field Medical                  Mustang
<br/>Air traffic control            Telos Tower
<br/></font>
<br/><font face='TahomaB' size='12'>Transport Aircraft</font>
<br/>
<font face='EtelkaMonospacePro' size='10'>
<br/>UH-60 Blackhawk                Buffalo 1/2
<br/>MH-6 Little Bird               Raven 1
<br/>CH-47 Chinook                  Grizzly 1
<br/>V-44X Blackfish (transport)    Titan 1
</font>
<br/>
<br/><font face='TahomaB' size='12'>Attack Aircraft</font>
<br/>
<font face='EtelkaMonospacePro' size='10'>
<br/>A-10 Thunderbolt               Hog 1
<br/>F-16 Fighting Falcon           Eagle 1
<br/>V-44X Blackfish (armed)        Spectre 1
<br/>AH-6 Attack Little Bird        Sparrow 1
<br/>AH-64 Apache                   Raider 1
</font>
<br/>
<br/>
<br/><font face='TahomaB' size='12'>Armor</font>
<br/>
<font face='EtelkaMonospacePro' size='10'>
<br/>M1 Abramms                     Sabre 1/2
<br/>Armored personnel carriers     Banshee 1/2/3/4
</font>
<br/>
"
]];

player createDiaryRecord ["diary", ["Radio Channels",
"
<font face='EtelkaMonospacePro' size='10'><br/>01 - Gunslinger Platoon Net</font>
<br/>            Used to communicate between infantry squads in field
<br/>
<font face='EtelkaMonospacePro' size='10'><br/>02 - Aviation</font>
<br/>            Used for air to air communications and CTAF/Air Traffic Control
<br/>
<font face='EtelkaMonospacePro' size='10'><br/>03 thru 09 - Other Platoon Nets</font>
<br/>            Used whenever there is an MCC or multiple platoons, also utilized if a Platoon comes in for a Platoon FTX
<br/>
<font face='EtelkaMonospacePro' size='10'><br/>10 / 11 - IDF-1 and IDF-2</font>
<br/>            Used to conduct indirect fire missions from artillery or mortars
<br/>
<font face='EtelkaMonospacePro' size='10'><br/>12 / 13 - CAS-1 and CAS-2</font>
<br/>            Used to call in fixed-wing or attack rotary close air support
<br/>
<font face='EtelkaMonospacePro' size='10'><br/>14 - Ground-To-Air</font>
<br/>            Used to conduct pick-up requests from logistical aviation units 
<br/>
<font face='EtelkaMonospacePro' size='10'><br/>15 - Logistics</font>
<br/>            Used by Apollo and Mustang personnel to dispatch where needed. 
<br/>
<font face='EtelkaMonospacePro' size='10'><br/>16 - FARP Requests</font>
<br/>            Used to communicate with Apollo personnel when you are inbound to a FARP as to what you need using the FARM acronym. FOXTROT - FUEL (state current fuel state if requesting FOXTROT) / ALPHA - AMMUNITION / ROMEO - REPAIRS / MIKE - MEDICAL (use triage category for multiple casualties) 
<br/>
<font face='EtelkaMonospacePro' size='10'><br/>17 - Convoy</font>
<br/>            Used when conducting a convoy 
<br/>
<font face='EtelkaMonospacePro' size='10'><br/>18 - Zeus</font>
<br/>            Used to communicate with a Zeus if required 
<br/>
<font face='EtelkaMonospacePro' size='10'><br/>19 - CAG</font>
<br/>            Classified 
<br/>
<font face='EtelkaMonospacePro' size='10'><br/>20 - Command</font>
<br/>            Used to coordinate across different platoons or other big picture items 
<br/>
"
]];
#endif

if (not (player diarySubjectExists "teamspeak")) then { player createDiarySubject ["teamspeak", "Teamspeak"] };

player createDiaryRecord ["teamspeak", ["Teamspeak server",
"
<br/>Address: ts3.7cav.us
<br/>Password: 7thCavalry
<br/>
<br/>The password is case-sensitive. The first time you connect to the Teamspeak server you must wait for your security level to reach 30 before
you will be able to enter any Teamspeak channels.
<br/>
<br/>Visitors and guests are welcome.
"
]];

player createDiaryRecord ["diary", ["Rules of conduct",
"
<br/>1. No fratricide.
<br/>2. No destruction of friendly equipment.
<br/>3. Players using character slots labelled TEAMSPEAK must be on Teamspeak
<br/>4. Combat Air Patrol and Combat Support must abide by specific rules of engagement
<br/>5. Weapons safe on base
<br/>6. No offensive language, sexual references, drug references, or racism of any kind will be tolerated
<br/>7. No vehicles allowed on runways or landing pads unless it is a support vehicle being used for that purpose
<br/>
<br/>If you see a player in violation of any of the above, contact a moderator or administrator (TeamSpeak).  For more information on these rules, see the billboards at base.
"
]];
