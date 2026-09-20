# Recipe picker

Pennylane take-home: type what you have at home, get ranked recipes from the Allrecipes dataset.

## User stories

**US1 — Find recipes from my pantry.** Enter pantry ingredients, see ranked results (photo, total time, Cook now / Missing N), open a recipe (photo, total + prep/cook, metric-friendly ingredients).

**US3 — Match explained.** Results are grouped: **Cook now** first (up to 8), then **Almost there** (1–2 missing, up to 3, only if Cook now did not fill the screen). Cards show what you still need; open a recipe for **In your pantry** vs **Still to get** (staples such as salt count as have). The first screen is a decision set of at most 8 — no paging through leftovers.

## Setup

```bash
bin/setup
bin/rails recipes:import
bin/rails server
```

`recipes:import` downloads the official gzip dataset. If S3 returns 403, download `recipes-en.json` locally (gitignored) and run:

```bash
bin/rails recipes:import[recipes-en.json]
```

```bash
bin/rspec
```

## Ranking

1. Fewer missing ingredients first (salt, pepper, water, and compound salt-and-pepper “to taste” lines are treated as staples and ignored).
2. Shorter total time (unknown times last).

Matching is exact on normalized names after Rails `singularize` (`eggs` matches `egg`; `flour` does not match `all-purpose flour`). Volume becomes ml, mass becomes g, with comma decimals (`6,1`). USDA FoodData Central cup weights turn the 15 most common dry/solid catalog ingredients (flour, sugar, butter, and the rest of that list) into grams; oils and other liquids stay ml.

## Out of scope for now

Accounts, cooking steps (not in the dataset), fridge photos, cuisine filters.
