# Recipe picker

Pennylane take-home: type what you have at home, get ranked recipes from the Allrecipes dataset.

## User stories

**US1 — Find recipes from my pantry.** Enter pantry ingredients, see ranked results (photo, total time, Cook now / Missing N), open a recipe (photo, total + prep/cook, metric-friendly ingredients).

**US3 — Match explained.** Results are grouped: **Cook now** first, then **Almost there** (1–2 missing) as a fallback, then **Needs more**. Cards show what you still need; open a recipe for **In your pantry** vs **Still to get** (staples such as salt count as have). Longer lists paginate 20 at a time.

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

1. Fewer missing ingredients first (salt, pepper, water, and black pepper are treated as staples and ignored).
2. Shorter total time (unknown times last).

Matching is exact on normalized names after Rails `singularize` (`eggs` matches `egg`; `flour` does not match `all-purpose flour`). Volume becomes ml, mass becomes g. USDA FoodData Central cup weights turn the 15 most common catalog ingredients (flour, sugar, butter, water, oils, and the rest of that list) into grams; everything else stays ml.

## Out of scope for now

Accounts, cooking steps (not in the dataset), fridge photos, cuisine filters.
