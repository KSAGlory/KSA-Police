# Changelog

## 3.0.1 — Foundation release

- Publish the v3 single-player-oriented wanted escalation foundation.
- Keep native wanted stars, six response profiles, crime hooks, cleanup, and Admin test commands.
- Use a unique dispatch token so delayed timers from an earlier pursuit cannot join a replacement pursuit at the same wanted level.
- Destroy tracked police NPCs immediately on resource stop so the resource's delayed cleanup timers cannot be cancelled before they run.
- Document the exact scope and limitations, especially stationary response vehicles and foot-only Slothbot pursuit.
