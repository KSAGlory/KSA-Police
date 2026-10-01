# KSA Police

An experimental wanted-level and NPC police foundation for MTA:SA Freeroam servers. It uses native wanted stars and [Slothbot](https://community.multitheftauto.com/index.php?p=resources&s=details&id=672) to dispatch armed officers against a wanted player. Its response table scales from regular police at one star to SWAT, federal-style, and military models at higher levels.

This is a **starting point for developers**, not a finished recreation of GTA: San Andreas single-player police AI. The original version was exercised on a private server: regular police, SWAT, and army units spawned. The public 3.0.1 package adds a small delayed-dispatch safety fix; its full gameplay behavior has **not** been independently re-tested as a release build.

## Download

Download the ready-to-install ZIP from [Releases](https://github.com/KSAGlory/KSA-Police/releases). It contains only this resource and its documentation—no server configuration, account data, or third-party resources.

## Requirements

- An MTA:SA server compatible with the functions used in `ksa_police/server.lua`.
- The separate **Slothbot** resource, started before KSA Police. Its `spawnBot`, `setBotAttackEnabled`, and `isPedBot` exports must be available. Slothbot is **not** included or relicensed here.
- A login system that sets player element data `loggedin` to a true value. Change the `eligible()` check if your server uses another authentication flag.
- The standard MTA `Admin` ACL group for the four administrative commands.
- A server that permits native wanted stars. The resource works only in interior `0`, dimension `0` by design.

## Installation

1. Install and start Slothbot according to its own instructions.
2. Copy the `ksa_police` folder into your server's `mods/deathmatch/resources/` directory.
3. Adapt the `loggedin` eligibility check to your server if necessary.
4. Start the resource with `start ksa_police`, or add it to your server startup configuration **after** Slothbot.
5. Use `/policestatus` as an Admin and try `/wanted 1` through `/wanted 6` on a test server.

There is no database or persistent wanted-state migration. Wanted level is cleared when a logged-in player joins or the resource starts.

## What it does

| Wanted level | Planned officers | Models and response-vehicle models |
| --- | ---: | --- |
| 1 | 3 | Regular police; police car |
| 2 | 6 | Regular police; police cars and bike |
| 3 | 10 | Regular police; police cars, bike, and helicopter model |
| 4 | 14 | SWAT and regular police; tactical trucks, police cars, and helicopter model |
| 5 | 18 | Federal-style, SWAT, and regular units; SUVs, tactical truck, police car, helicopter, and bike models |
| 6 | 24 | Military, SWAT, and federal-style units; tank, military truck, tactical truck, police car, helicopter, and SUV models |

The figures are **dispatch targets**, not guarantees that every NPC will spawn or remain alive. Vehicle models are created as **stationary scene/response vehicles**. They do not carry officers or drive. The helicopter model does not fly a pursuit, and the tank does not fight. Officers use Slothbot's `chasing` mode on foot.

The script raises wanted level for damage or death of a civilian/police NPC, carjacking, and gunfire near civilian NPCs. It clears pursuit on death, quit, or wanted level zero. If no tracked officer is near the player for 75 seconds, it reduces the level one star. It replaces under-strength dispatches after a delay. Admin commands are:

| Command | Purpose |
| --- | --- |
| `/wanted <0-6>` | Set your wanted level and dispatch the corresponding response. |
| `/policeclear` | Clear your wanted level and tracked pursuit. |
| `/policestatus` | Show the tracked unit and vehicle counts. |
| `/policedebug on` / `off` | Toggle your dispatch debug messages in the server log. |

## Important limitations

- This release does **not** implement police driving, occupied police cars, roadblocks, helicopter flight/attacks, arrests, or GTA:SA's complete search and spawn rules.
- Spawn positions use an angle and distance around the player, not road/pathfinding or a camera visibility test. They may be unsuitable for steep terrain or obstacles.
- Pursuit is restricted to world interior/dimension `0`. Interior travel clears tracked units rather than following the player inside.
- The crime hooks assume other NPC resources use ordinary MTA ped elements. You may need to adapt the civilian exclusions for your server.
- Wanted levels and police state are intentionally session-only. There is no account or inventory database access.
- The source's bot-destruction delay and reliance on Slothbot need stress testing on each target server, particularly on resource restart.

See [docs/manual-testing.md](docs/manual-testing.md) for a focused test checklist before using it on a live server.

## Contributing

Improved pursuit behavior, safe pathfinding, and compatibility fixes are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request.

## Author and Community

- Maintainer: **KSAGlory**
- Community: [discord.gg/ksahub](https://discord.gg/ksahub)

## License

KSA Police's source is released under the [MIT License](LICENSE).
