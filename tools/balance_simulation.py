#!/usr/bin/env python3
"""Standalone economic balance check for the Godot project's numeric design.

Mirrors the core formulas from game/scripts/autoload/{PlayerPlantations,
Economy,Crops,Paintings}.gd in plain Python so the numbers can be sanity
checked (and iterated on) without needing to run the actual Godot editor.
This is a design/QA tool, not part of the shipped game.

Run: python3 tools/balance_simulation.py
"""

import random

random.seed(42)

# --- Mirrored constants (keep in sync with the .gd sources noted above) ---

TILE_COST = 500.0
WORKER_DAILY_WAGE = 1.0
MAX_WORKERS = 500
REFERENCE_TILE_COUNT = 50.0
RIVER_YIELD_MULTIPLIER = 2.0
REFERENCE_PERIOD_DAYS = 30.0

REFERENCE_YIELD_ST_LOUIS_TOBACCO = 433  # best tobacco city, docs/MECHANIKI_EKONOMICZNE.md pkt. 3

SEASONAL_YIELD_FACTOR = {
    1: 0.4, 2: 0.7, 3: 1.0, 4: 1.0, 5: 0.8, 6: 0.6,
    7: 0.8, 8: 1.0, 9: 1.0, 10: 0.7, 11: 0.4, 12: 0.3,
}

BASE_CROP_PRICE = 50.0  # fixed in this session — see Crops.gd comment
CROP_DRIFT_RANGE = 0.02
TRANSPORT_COST_ST_LOUIS_TO_NY = 4  # Crops.TRANSPORT_COST["new_york"]["st_louis"]

STARTING_MONEY = 50000.0
BANKRUPTCY_THRESHOLD_DAYS = 60

CATEGORY_BASE_VALUE_AVG = (15000 + 8000 + 6000 + 6000 + 9000 + 5000 + 7000 + 12000) / 8.0


def month_of_day(day: int) -> int:
    return 1 + (day // 30) % 12


def simulate(weeks: int = 52, river_tiles_bought_first: bool = True) -> None:
    money = STARTING_MONEY
    tiles = 0
    river_tiles = 0
    workers = 0
    stored_goods = 0
    crop_price = BASE_CROP_PRICE
    day = 0
    days_in_debt = 0
    bankrupt_at_week = None
    first_auction_affordable_week = None

    print(f"{'week':>4} {'day':>5} {'money':>10} {'tiles':>6} {'workers':>7} {'stored':>7} {'price':>6}")

    for week in range(1, weeks + 1):
        # Strategy: keep buying tiles (prioritising river-adjacent, up to
        # REFERENCE_TILE_COUNT) and topping up workers to MAX_WORKERS as
        # soon as affordable, then harvest + sell weekly.
        while tiles < REFERENCE_TILE_COUNT and money >= TILE_COST + 1000:
            money -= TILE_COST
            tiles += 1
            # Assume roughly half of bought tiles end up river-adjacent
            # (matches a compact layout hugging the river column).
            if river_tiles_bought_first and river_tiles < REFERENCE_TILE_COUNT * 0.4:
                river_tiles += 1

        if workers < MAX_WORKERS:
            workers = MAX_WORKERS

        # Recurring wage (the bug fixed in this session: this used to be a
        # one-off hiring cost instead of a real daily wage).
        wage_cost = workers * WORKER_DAILY_WAGE * 7
        money -= wage_cost

        # Harvest (calculate_harvest formula from PlayerPlantations.gd) —
        # time-gated fix: yield scales with days since last harvest (7 here,
        # since we harvest weekly), against REFERENCE_PERIOD_DAYS (30).
        normal_tiles = tiles - river_tiles
        effective_tiles = normal_tiles + river_tiles * RIVER_YIELD_MULTIPLIER
        worker_factor = workers / 500.0
        tile_factor = effective_tiles / REFERENCE_TILE_COUNT
        seasonal_factor = SEASONAL_YIELD_FACTOR[month_of_day(day)]
        time_factor = 7 / REFERENCE_PERIOD_DAYS
        harvest = int(REFERENCE_YIELD_ST_LOUIS_TOBACCO * worker_factor * tile_factor * seasonal_factor * time_factor)
        stored_goods += harvest

        # Ship & sell everything weekly.
        if stored_goods > 0:
            money -= TRANSPORT_COST_ST_LOUIS_TO_NY * stored_goods
            money += stored_goods * crop_price
            stored_goods = 0

        # Crop price weekly drift (Crops.gd _on_day_advanced, scaled by 1 week).
        crop_price = max(1.0, crop_price * (1.0 + random.uniform(-CROP_DRIFT_RANGE, CROP_DRIFT_RANGE)))

        day += 7

        if money < 0:
            days_in_debt += 7
        else:
            days_in_debt = 0
        if days_in_debt >= BANKRUPTCY_THRESHOLD_DAYS and bankrupt_at_week is None:
            bankrupt_at_week = week

        if first_auction_affordable_week is None and money >= CATEGORY_BASE_VALUE_AVG * 1.3:
            first_auction_affordable_week = week

        if week % 4 == 0 or week == weeks:
            print(f"{week:>4} {day:>5} {money:>10.0f} {tiles:>6} {workers:>7} {stored_goods:>7} {crop_price:>6.2f}")

    print()
    print(f"Pierwszy tydzień, w którym stać na przeciętną aukcję (~{CATEGORY_BASE_VALUE_AVG * 1.3:.0f} M): "
          f"{first_auction_affordable_week}")
    print(f"Bankructwo (60 dni z rzędu na minusie): "
          f"{'tydzień ' + str(bankrupt_at_week) if bankrupt_at_week else 'nie wystąpiło w symulacji'}")


if __name__ == "__main__":
    simulate()
