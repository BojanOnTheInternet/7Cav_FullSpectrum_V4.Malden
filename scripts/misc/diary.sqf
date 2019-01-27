if (!hasInterface) exitWith {};

waitUntil {!isNull player};

#define BRIEFING
#ifdef BRIEFING
player createDiaryRecord ["diary", ["Special Operations",
"
Special operations consist of a series of missions executed by a small team.  That team has specific player slots in the server lobby, all beginning with 'SPECOPs'.
It is intended to be a self-contained unit, with its own pilot, medics, marksmen and so forth.  Missions are requested via the satellite phone on the desk in the SPECOPs
building.  Once requested, a series of missions will be provided to the team.  Failure on any mission will end the current series, requiring the team to make a request
for a new series of missions.  Only SPECOPs members may request missions, complete the essential steps to a mission, or receive notifications from Special Operations Command.
<br/>
<br/>
During missions that take place in cities and villages, the team may encounter enemy vehicles where the crew has dismounted in town before the SPECOPs team has arrived.
Those vehicles may be taken and used by the SPECOPs team.  If destroyed, they do not respawn.  If damaged, it might not be possible to repair them, depending on
the vehicle type.
<br/>
<br/>
SPECOPs members are subject to fatigue and weight limits and are further restricted to first person gameplay.  At the same time, they are better marksmen than regular infantry.
<br/>
<br/>
Note that the RPG gunner and team leader may operate armored vehicles as well as the Kajman attack helicopter (in cooperation with the
SPECOPs pilot).  As with regular infantry, any team member may drive unarmored vehicles.
"
]];

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
<br/><font size='12'>Personnel</font>
<br/>
<font face='EtelkaMonospacePro' size='10'>
<br/>Air traffic control           Telos Tower
<br/>JTAC                          Infidel
<br/>
<br/><font size='12'>Transport Aircraft</font>
<br/>
<font face='EtelkaMonospacePro' size='10'>
<br/>CH-67 Huron                   Grizzly 1
<br/>Mi-290 Taru                   Grizzly 2 and 3
<br/>UH-80 Ghost Hawk (Black)      Buffalo 1
<br/>UH-80 Ghost Hawk (Camo)       Buffalo 2
<br/>UH-80 Ghost Hawk (Recon)      Recon 1
<br/>MH-9 Hummingbird (Black)      Sparrow 1
<br/>MH-9 Hummingbird (Camo)       Sparrow 2
<br/>V-44X Blackfish (Infantry)    Condor 1
<br/>V-44X Blackfish (Vehicle)     Condor 2
</font>
<br/>
<br/><font size='12'>Combat Support</font>
<br/>
<font face='EtelkaMonospacePro' size='10'>
<br/>A-164 Wipeout                 Eagle 1
<br/>AH-99 Blackfoot               Raider 1
<br/>WY-55 Hellcat                 Raider 2 and 3
<br/>V-44X Blackfish (armed)       Spectre
<br/>Mortar                        Odin
</font>
<br/>
<br/><font size='12'>Combat Air Patrol</font>
<br/>
<font face='EtelkaMonospacePro' size='10'>
<br/>F/A-181 Black Wasp II         Eagle 2 and 3
</font>
<br/>
<br/>Additional aircraft acquire callsigns by type.  Attack jets are Eagles, attack helicopters are Raiders, etc.
<br/>
<br/><font size='12'>Armor</font>
<br/>
<font face='EtelkaMonospacePro' size='10'>
<br/>M2A1 Slammer                  Sabre 1 and 2
<br/>IFV-6a Cheetah                Flyswatter
<br/>Armored personnel carriers    Tincan
</font>
<br/>
<br/>Additional armored vehicles acquire callsigns by type.  Main battle tanks are Sabres, etc.
<font face='EtelkaMonospacePro' size='10'>
</font>
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

player createDiaryRecord ["diary", ["Mission key bindings",
"
B - When flying a transport helicopter and depending on circumstances, this key will start a sling interaction, detach all slung cargo, attach a Taru pod, or detach a Taru pod.  Matches the control setting for 'Helicopter Movement, Rope interaction'.<br/>
H - Holster or sling your current weapon.<br/>
V - When jogging or running with rifle in hand, this key will cause you to jump.  Matches the control setting for 'Infantry Movement, Step over'.<br/>
V - When descending in a parachute, this key will cut away your chute.<br/>
V+V - When ejecting from an aircraft capable of paradropping troops, this key will start a paradrop.  Above 100m will start a static line drop and above 250m will start a HALO drop.<br/>
PAUSE/BREAK - Insert or remove earplugs.<br/>
CTRL+SHIFT+U - Hide or show the mission HUD, which shows various labels and icons on objects in the world.<br/>
CTRL+SHIFT+R - Enable or disable microphone clicks and line noise for transmissions received on the group channel.<br/>
CTRL+SHIFT+G - Enable or disable variable-strength throwing.  This is for grenades, light sticks, etc.<br/>
CTRL+SHIFT+SCROLL - Enable or disable fatigue/stamina.  This is only available to classes where fatigue/stamina is turned off by default.<br/>
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

if (not (player diarySubjectExists "credits")) then { player createDiarySubject ["credits", "Credits"] };

player createDiaryRecord ["credits", ["Strongpoint",
"
<br/>
<font align='center'>Design</font><br/>
<font size='16' align='center'>Dakota (7th Cavalry)</font><br/>
<br/>
<font align='center'>Scripting</font><br/>
<font size='16' align='center'>JB</font><br/><br/>
"
]];