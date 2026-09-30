# Manual test checklist

Use a separate test server with Slothbot running. Verify that its exports are available and that the login system sets `loggedin` for the test account. Keep the server console and client debug output visible.

1. Start KSA Police and confirm no resource-start error.
2. Log in, confirm native wanted stars start at zero, then issue `/wanted 1` through `/wanted 6` individually. Check the requested officer types and tracked counts with `/policestatus`.
3. Check the actual result, not just the wanted-star icon: officers spawn and pursue on foot, while response vehicles remain stationary scenery.
4. Damage a civilian NPC, damage a dispatched police NPC, carjack, and fire near a civilian. Confirm wanted changes only for the expected actions.
5. At each level, walk and drive through open areas. Observe bot movement, replacement, FPS/server load, and whether units are spawned in bad terrain.
6. Clear pursuit with `/policeclear`; then test death, disconnect/reconnect, and resource restart. Inspect for leftover NPCs, vehicles, timers, or errors.
7. Check a nonzero interior/dimension. This build intentionally does not dispatch there.
8. Wait beyond the configured escape interval away from tracked officers and check that stars reduce.

Record actual observations for your own server. A successful resource start does not prove reliable gameplay behavior.
