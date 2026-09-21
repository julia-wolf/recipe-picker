# Recipe picker

Pennylane take-home: type what you have at home, get ranked recipes from the Allrecipes dataset.

## User persona

The user persona is a home-first weeknight cook. They cook often and already know their way around a kitchen; the hard part is choosing dinner from what is already here, not learning how to cook. They use an iPad in the kitchen or at the table, at arm’s length, and type the foods they have — names, not amounts. Within a couple of minutes they want to know what they can make tonight, without another trip to the shop. Grams and millilitres are used because the cook is assumed to be based in the EU.

I landed on this from a small exploratory survey of six people who cook at home. Most cooked often, and the strongest signal was to start from ingredients already in the kitchen rather than browsing recipes. That was enough for me to pick a persona and prioritize for a prototype — not a claim that most cooks look like this. Kitchen iPad is a product choice on top of that, not something the survey asked.

## User stories

### Find tonight’s dinner

User Story: As a weeknight cook, I want to type what I have at home, so I can quickly find recipes for tonight.

Acceptance criteria:

```gherkin
Scenario: The home page explains how to start
  Given I have not typed what I have at home
  When I open the app
  Then I see how to list the foods in my kitchen

Scenario: I list foods by name
  Given I am looking for tonight’s dinner
  When I type foods separated by commas or new lines
  Then I can use names, not amounts

Scenario: Egg and eggs are the same food
  Given a recipe lists eggs
  When I type egg
  Then that recipe can still match

Scenario: Results help me choose quickly
  Given I have typed what I have at home
  When recipes are shown
  Then each result has a photo of the dish
  And I see how long it takes
  And I see whether I can cook it now or how many things I still need

Scenario: I open a recipe
  Given I see a result I like
  When I tap it
  Then I see a photo of the dish
  And I see total time plus prep and cook
  And amounts are in grams and millilitres
  And gram amounts are whole numbers
  And oils and other liquids stay in millilitres

Scenario: Everyday kitchen basics are assumed
  Given a recipe uses salt, pepper, or water
  When I search with other foods I have
  Then those basics count as already in the kitchen
```

Out of scope:
- A photo of the fridge as the way to say what’s in stock
- Signing in, saving favourites, or star ratings
- Step-by-step cooking instructions (the recipes we have don’t include them)
- Filtering by cuisine

### Decide from what’s already here

User Story: As a weeknight cook, I want to see what I can make with what’s already here and what’s still missing, so I can decide in a few minutes without browsing leftover recipes.

Acceptance criteria:

```gherkin
Scenario: I can cook now comes first
  Given some recipes use only what I have
  When results are shown
  Then those recipes come first
  And I see at most nine recipes at a time
  And I am not asked to browse leftover recipes

Scenario: Closer matches come before weaker ones
  Given two recipes both use a food I have
  And one is missing fewer extra ingredients
  When results are shown
  Then the closer match appears first

Scenario: The quicker recipe comes first when they need the same extras
  Given two recipes need the same number of extra ingredients
  And one takes less time
  When results are shown
  Then the quicker one appears first

Scenario: Recipes without a time come after timed ones
  Given two recipes need the same extras
  And only one lists how long it takes
  When results are shown
  Then the one with a time appears first

Scenario: Almost-ready recipes fill leftover room
  Given I can cook fewer than nine recipes now
  And other recipes are missing 1 to 3 things
  When results are shown
  Then leftover room is filled with those almost-ready recipes
  And I see at most nine recipes in total
  And recipes missing 4 or more things are not offered

Scenario: Pet recipes stay off the dinner list
  Given a recipe is for pet treats or pet food
  When results are shown
  Then that recipe is not offered

Scenario: I see what I still need and what is assumed
  Given a recipe is missing something
  When I look at the result
  Then I see what I still need
  And I see salt-and-pepper lines the recipe assumes I have

Scenario: A recipe I can cook now does not list a still-need line
  Given I have everything for a recipe
  When I look at the result
  Then I do not see a still-need line

Scenario: Opening a recipe splits pantry from still to get
  Given I cannot cook a recipe yet
  When I open it
  Then I see what is already in my pantry
  And I see what I still need to get

Scenario: Opening a recipe I can cook now skips still to get
  Given I can cook a recipe now
  When I open it
  Then I see what is in my pantry
  And I do not see a still-to-get list

Scenario: Salt and pepper to taste is on hand
  Given a recipe says salt and pepper to taste
  When I search with other foods I have
  Then that line counts as on hand, not missing

Scenario: Matches exist but need too much extra
  Given recipes use a food I typed
  And every one of them still needs more than three extra ingredients
  When results would be shown
  Then the page tells me they need more than three extras
  And the wording fits one food or several

Scenario: That food name is not used as written
  Given no recipe uses that food name as written
  When I search
  Then the page tells me so
```

Out of scope:
- Opening recipes that still need four or more extra ingredients
- Finding “all-purpose flour” by typing only “flour”
- A shopping list
- Treating every spice as already at home

## Setup

```bash
bin/setup
bin/rails recipes:import
bin/rails server
```

`recipes:import` downloads the official gzip dataset.
```bash
bin/rspec
```
