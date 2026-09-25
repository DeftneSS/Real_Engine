# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Running and testing

Godot 4.7 project (Forward Plus). There is no CLI build/lint/test pipeline and no automated tests.

- Run with the Godot 4.7 editor (`godot4 --path .` from this directory). Main scene: `ui/main_menu.tscn`.
- Local multiplayer quick-test: set `multiplayer_test = true` on the `Game` node in `autoloads/game.tscn` and fill `test_players` with `PlayerDataResource` entries (first entry is the server). Launching multiple instances (Debug > Customize Run Instances) then routes to `lobby/lobby_test.tscn`, which auto-creates server/client peers, tiles the windows per client index, and starts `Game.main_scene` once everyone connects. Only active in debug builds.

## Architecture

Multiplayer party-game skeleton on Godot's high-level multiplayer API (ENet). Three autoloads plus RPC-driven scene flow.

### Autoloads (`autoloads/`)
- **`Game`** (`Game.instance`) — authoritative list of connected players (`Array[Statics.PlayerData]`), `main_scene` to load when a match starts, and RPCs (`set_player_role`, `set_player_vote`, `update_indices`) that keep the player list in sync. Also handles window content scaling and a debug player-id label.
- **`Lobby`** (`Lobby.instance`) — scene-transition helpers (`go_to_menu/host/join/lobby`) and handlers for `multiplayer` signals (peer connect/disconnect, server disconnect, connection failure). New peers announce via the `send_data` RPC; the server assigns an `index` and rebroadcasts. If a peer drops mid-game, everyone returns to the lobby.
- **`Debug`** — debug-only on-screen log (`Debug.log(msg)`), broadcast to all peers when online; tags window titles `Server` / `Client N`.

`scripts/statics.gd` holds constants (`MAX_CLIENTS`, `PORT`), the `Role` enum, and the inner `PlayerData` class (id/name/index/role/vote, `to_dict`/`from_dict` for sending over RPC/spawners). `PlayerData.id` equals the peer's `multiplayer.get_unique_id()`.

### Scene flow
`ui/main_menu.tscn` → `lobby/host_screen.tscn` (creates server) or `lobby/join_screen.tscn` (creates client) → `lobby/waiting_screen.tscn` (role selection + ready vote; when all are ready with valid roles the server runs a countdown RPC, then RPCs everyone into `Game.main_scene`). Transitions happen via RPC so all peers move in lockstep.

### Gameplay
- **Level** (`scene/level_test.gd`) — server-only spawning. Players are spawned through `PlayerSpawner` (a `MultiplayerSpawner` with a custom `spawn_function` that takes `PlayerData.to_dict()`, names the node by peer id, sets authority, and places it at `SpawnPoints` child `index`). Enemies are `add_child`ed by the server under `Enemies`, replicated by the `MultiplayerSpawner` there.
- **Input** (`input_synchronizer.gd`, at repo root) — `InputSynchronizer` (`MultiplayerSynchronizer` subclass) on each player. Only the owning peer reads `Input`; `move_input` is synced continuously, while one-shot actions (`jump`, `dash`, `attack`) are set by `call_local` RPCs on every peer.
- **Player** (`players/player.gd`) — `CharacterBody3D` whose `_physics_process` runs on *all* peers from the synced inputs (each peer simulates every player; one-shot flags are consumed and reset there). The authority corrects drift by periodically RPCing `_sync(position, velocity)` (lerped) from `SyncTimer`. Camera/mouse look is authority-only. Players join the `"players"` group.
- **Enemies** (`enemies/enemy.gd`) — simulated only on the multiplayer authority (the server), chasing the nearest node in the `"players"` group; state replicated via `MultiplayerSynchronizer`.
- **Weapons** (`weapons/`) — `Weapon` base (`weapon.tscn`, has `AttackCooldownTimer`); `attack(direction)` handles cooldown and calls the virtual `_attack(direction)`, which subclasses override (`BasicStave`, `Unarmed`). Subclasses set `weapon_name`/`damage` in `_init()`. The player instantiates its weapon in `_ready()` under `Model/WeaponSocket` and attacks along the camera's forward vector. `Player.attack()` only runs on the owning peer (other peers' cameras aren't rotated, so they can't compute aim). `BasicStave._attack` sends the origin/aim to the server (`_request_projectile.rpc_id(1, ...)`, validated against `Weapon.wielder_id`), and the server calls `ProjectileSpawner.spawn(data)`; the spawner's `spawn_function` builds the `Projectile` identically on every peer. Never `add_child` projectiles directly — that creates duplicates on peers.

### Conventions
- Player-list state changes go through `@rpc("any_peer", "reliable", ...)` functions on `Game`/`Lobby` rather than direct assignment (the server is not always the one editing — see `set_player_role`/`set_player_vote`).
- Dev-only behavior (`Debug` overlay, `multiplayer_test`, player-id label) is gated on `OS.is_debug_build()`.
- Code uses static typing throughout (typed vars, typed loop variables, `class_name` on gameplay scripts).
