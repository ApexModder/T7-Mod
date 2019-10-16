<h1 align="center">
  <br>
  <a href="#"><img src="https://www.logolynx.com/images/logolynx/9b/9b46de160f0bc8164dd449d195404f52.jpeg" alt="Markdownify" width="200"></a>
  <br>
  BlackOps-Overhauled
  <br>
</h1>

<h4 align="center">Downporting code from the Black Ops series into Black Ops 1 <a href="http://electron.atom.io" target="_blank"></h4>

<p align="center">
  <a href="https://discord.gg/rTTb3uB">
    <img src="https://img.shields.io/badge/chat-Discord-blue.svg?label=Discord"
         alt="Discord">
  </a>

  <a href="https://www.paypal.me/RobsonLawson">
    <img src="https://img.shields.io/badge/$-donate-1EAEDB.svg?maxAge=2592000&amp;style=flat">
  </a>
</p>

## Description

A **Call of Duty: Black Ops 1 Zombies** mod involving rescripting and downporting several features from the newer releases of Call of Duty: Black Ops (2, 3, 4) Come check out the development livestream at [https://www.twitch.tv/apexmdr/](https://www.twitch.tv/apexmdr/)
Future and upcoming features can be viewed by [clicking here](https://github.com/ApexModder/T7-Mod/projects/1?fullscreen=true)

## Current Features & Changes

- **Player Trigger**
	- These are triggers which handle all logic and prompts from each player.
	- Every player sees a different hint string

- **VisionSet System**
	- Removed the vision system: **`_zombiemode.csc`**
	- Updated with a new and improved version
	- Visions can be applied via server side and can intreact with the client side

- **Rewritten Powerups System**
	- No longer any hard coded logic in the main powerups script
	- All powerup logic is automated; individual powerups just specify what happens during, but are not limited to, **`'onGrab'`**, **`'onTimeout'`**, **`'onTimedPowerupStart'`**
	- Organized all powerups into their own individual scripts
	- [Downported the Black Ops 3 powerup HUD logic](https://streamable.com/ny2kn)
	- Supported Powerups:
		* Bonfire Sale
		* Bonus Points
		* Carpenter
		* Double Points
		* Empty Clip
		* Fire Sale
		* Free Perk
		* Max Ammo
		* Insta Kill
		* Lose Perk
		* Lose Points (Player / Team)
		* Minigun
		* Nuke
		* Random Weapon
		* Tesla


- **Rewritten Perk System**
	- Perks are no longer required to be named with the format: **`specialty_`**
	- Perks can still have **`specialty_`** format tied to them but can be set and unset with the perk
	- Perk icons moved to the game menu in order to reduce the amount of HudElements used in script
	- No longer any hard coded logic in main perks script
	- [Perk bottle now supports **`'indexed'`** models and **`'weaponOptions.csv'`**](https://streamable.com/vnb3a)
		- Unfortunately this change means we are stuck with Black Ops perk bottles, due to how materials have to be set up for weapon options to work.
		- Up side to this means, we only use 1 weapon file slot and 1 xmodel slot for every perk bottle.
	- All perks seperated in to a script per perk
	- Perk machines now use **`PlayerTriggers`**
	- Perk machines now use Black Ops 2 and 3 models
	- Supported Perks:
		* Juggernog
		* Double Tap 2.0
		* Speed Cola
		* Quick Revive
		* PHD Flopper
		* Stamin Up
		* Deadshot
		* Mule Kick
		* Tombstone
		* Whos Who
		* Vulture Aid
		* Electric Cherry
		* Widows Wine

- **Rewritten Pack-A-Punch**
	- Pack-A-Punch now uses a state based **`xanims`**
	- Pack-A-Punch now uses a **`PlayerTriggers`**
	- Pack-A-Punch now uses Black Ops 3 models and animations

- **Rewritten Magicbox**
	- Magicbox now uses state based xanims
	- Magicbox now uses **`PlayerTriggers`**
	- All Magicbox logic moved out of **`_zombiemode_weapons.gsc/.csc`** into **`_zm_magicbox.gsc/.csc`**
	- Fixed Magicbox cycle being FPS based
	- Magicbox now uses Black Ops 2 models and animations

- **Rewritten Weapons Script**
	- Weapons are now loaded from CSV string tables
		- Removed the need for each level to manually include weapons in both client and server sides
		- Auto-registers and loads correct weapons on the client side
		- Auto-registers the correct offhand weapon types
		- Added callback allowing a script for a specific weapon to be loaded
	- Many weapon utility functions downported from Black Ops 3
	- **`weapon_give()`** now supports any weapon type not just primary and melee weapons
		- Swaps out lethal, tactical, and melee weapons automatically
	- Downported **`_zm_lighning_chain`** script
		- Allows for custom lightning chains, mainly used for Wunderwaffe and Dead wire
	- Downported **`_zm_melee_weapons`** script
		- Automaticly handles, changing knife and ballistic knife weapons
		- [Adds **`fallback`** weapons that are given when the player has no primary weapons](https://streamable.com/iodg6)
	- Downported **`_zm_place_mines`** script
		- Allows for easy regisration of custom placeable mines

## Disclaimer

This mod has **only** been tested on Kino Der Toten so other maps will most likely crash due to refactoring functions and code of the original scripts. Support for other maps will be announced once the base mod's major functions and script changes have been fully completed.

This mod may have potential bugs and issues that have not been documented. Feel free to provide feedback on such problems so that they may fixed with the initial release of the mod. Thank you

## Contributors and Honorable Mentions

- **_ApexModder_** - Mod Owner
- **_xSanchez78_**
	- Ported **Black Ops 3** models and anims to **Black Ops 1**
	- Created effects for various perks from scratch
	- Help with soundaliases
	- **Huge** scripting help involving the **VisionSet System**, **PlayerTrigger System**, and various other downported scripts
- **_MotoLegacy_** - HighDef Black Ops 1 styled perk and powerup shaders
- **_Scobalula_** - For developing and releasing various of his tools (**Greyhound**, **HydraX**)
- **_Tom BMX_** - For developing and releasing **FF Extractor**
- **_DTZxPorter_** - For developing and release **BassDrop**
	- Thanks to **_Papa Pop_** in the **LinkerMod** discord server for fixing issues involving sound.

## License

[GNU GENERAL PUBLIC LICENSE](https://github.com/ApexModder/T7-Mod/blob/master/LICENSE)
