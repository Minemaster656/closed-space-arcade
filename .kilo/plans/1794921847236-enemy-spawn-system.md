# Enemy Spawn System Plan

## Goal
Distance-tiered spawn weights, shooter enemy, metal shard collectable.

## Changes
1. AsteroidSpawner: add `distance`, recalc weights at thresholds 5/10/20.
2. Game: set spawner.distance and speed multiplier for shooter.
3. ShooterEnemy script for prefab: static drift, shoot every 1s, 5 HP, drop 1-2 shards.
4. Metal shard AsteroidType with collectible, metal_value=3, texture metal_small.png.
5. Spawner instantiates shooter when selected.

## Validation
Run game, check progression, shooter fire, shard pickup.
