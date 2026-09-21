require "rails_helper"

RSpec.describe RecipeMatcher do
  def create_recipe(title:, ingredients:, prep_time: 10, cook_time: 10)
    recipe = Recipe.create!(title: title, prep_time: prep_time, cook_time: cook_time)
    ingredients.each { |name| add_ingredient(recipe, name) }
    recipe
  end

  def add_ingredient(recipe, name)
    ingredient = Ingredient.find_or_create_by!(normalized_name: IngredientNormalizer.call(name)) do |record|
      record.name = name
    end
    recipe.recipe_ingredients.create!(ingredient: ingredient, display_text: name)
  end

  def count_selects(&block)
    count = 0
    callback = lambda do |_name, _started, _finished, _id, payload|
      sql = payload[:sql]
      count += 1 if sql.match?(/\ASELECT/i) && !sql.match?(/pg_|SCHEMA/i)
    end
    ActiveSupport::Notifications.subscribed(callback, "sql.active_record", &block)
    count
  end

  describe ".search" do
    it "returns no results for a blank query" do
      create_recipe(title: "Omelette", ingredients: [ "egg" ])

      expect(described_class.search("")).to be_empty
      expect(described_class.search("   ")).to be_empty
      expect(described_class.search("")).not_to be_too_far
      expect(described_class.search("")).not_to be_staples_only
    end

    it "normalizes pantry terms before matching" do
      recipe = create_recipe(title: "Omelette", ingredients: [ "Egg" ])

      results = described_class.search("EGG")

      expect(results.map(&:recipe)).to eq([ recipe ])
      expect(results.first.missing_count).to eq(0)
    end

    it "matches ingredients only by exact normalized name" do
      exact = create_recipe(title: "Flour mix", ingredients: [ "flour" ])
      create_recipe(title: "Bread", ingredients: [ "all-purpose flour" ])

      expect(described_class.search("flour").map(&:recipe)).to eq([ exact ])
    end

    it "matches singular pantry terms to plural recipe ingredients" do
      recipe = create_recipe(title: "Omelette", ingredients: [ "eggs" ])

      expect(described_class.search("egg").map(&:recipe)).to eq([ recipe ])
    end

    it "ignores a leading amount on a pantry term" do
      recipe = create_recipe(title: "Omelette", ingredients: [ "eggs" ])

      expect(described_class.search("6 eggs").map(&:recipe)).to eq([ recipe ])
      expect(described_class.search("6eggs").map(&:recipe)).to eq([ recipe ])
    end

    it "counts missing non-staple ingredients" do
      recipe = create_recipe(title: "Stir fry", ingredients: [ "chicken", "onion", "salt" ])

      result = described_class.search("chicken").find { |row| row.recipe == recipe }

      expect(result.missing_count).to eq(1)
    end

    it "does not treat staples as a pantry match" do
      create_recipe(title: "Salted chicken", ingredients: [ "chicken", "salt" ])
      create_recipe(title: "Just salt", ingredients: [ "salt" ])

      expect(described_class.search("salt").map(&:recipe)).to eq([])
    end

    it "ignores black pepper as a staple phrase, not the word black" do
      peppered = create_recipe(title: "Peppered chicken", ingredients: [ "chicken", "black pepper" ])
      inky = create_recipe(title: "Squid ink", ingredients: [ "black" ])

      expect(described_class.search("black pepper").map(&:recipe)).to eq([])
      expect(described_class.search("black").map(&:recipe)).to eq([ inky ])
      expect(described_class.search("chicken").find { |row| row.recipe == peppered }.missing_count).to eq(0)
    end

    it "covers compound salt-and-pepper lines as staples" do
      recipe = create_recipe(
        title: "Seasoned eggs",
        ingredients: [ "egg", "salt and ground black pepper to taste" ]
      )

      result = described_class.search("egg").find { |row| row.recipe == recipe }

      expect(result.missing_count).to eq(0)
      expect(result.have).to include("salt and ground black pepper to taste")
      expect(result.staples).to include("salt and ground black pepper to taste")
      expect(result.missing).to eq([])
    end

    it "does not treat garlic salt as a staple" do
      recipe = create_recipe(title: "Seasoned eggs", ingredients: [ "egg", "garlic salt" ])

      result = described_class.search("egg").find { |row| row.recipe == recipe }

      expect(result.missing_count).to eq(1)
      expect(result.missing).to include("garlic salt")
    end

    it "treats water as a staple" do
      recipe = create_recipe(title: "Boiled egg", ingredients: [ "egg", "water" ])

      result = described_class.search("egg").find { |row| row.recipe == recipe }

      expect(result.missing_count).to eq(0)
      expect(result.staples).to include("water")
    end

    it "does not treat bell pepper or cayenne as staples" do
      recipe = create_recipe(
        title: "Peppers",
        ingredients: [ "egg", "green bell pepper chopped", "cayenne pepper" ]
      )

      result = described_class.search("egg").find { |row| row.recipe == recipe }

      expect(result.missing_count).to eq(2)
      expect(result.missing).to include("green bell pepper chopped", "cayenne pepper")
    end

    it "excludes Pet Treats and Pet Food from results" do
      dinner = create_recipe(title: "Omelette", ingredients: [ "egg" ])
      treats = create_recipe(title: "Dog biscuits", ingredients: [ "egg" ])
      treats.update!(category: "Pet Treats")
      kibble = create_recipe(title: "Kibble loaf", ingredients: [ "egg" ])
      kibble.update!(category: "Pet Food")
      hot_dog = create_recipe(title: "Fair hot dog", ingredients: [ "egg" ])
      hot_dog.update!(category: "Hot Dogs and Corn Dogs")

      expect(described_class.search("egg").map(&:recipe)).to contain_exactly(dinner, hot_dog)
    end

    it "does not query once per recipe when scoring matches" do
      3.times { |i| create_recipe(title: "Chicken #{i}", ingredients: [ "chicken", "onion" ]) }

      selects = count_selects { described_class.search("chicken") }

      expect(selects).to be <= 5
    end

    it "ranks fewer missing ingredients first" do
      almost = create_recipe(title: "Almost", ingredients: [ "chicken", "onion" ])
      exact = create_recipe(title: "Exact", ingredients: [ "chicken" ])

      expect(described_class.search("chicken").map(&:recipe)).to eq([ exact, almost ])
    end

    it "ranks shorter total time after equal missing counts" do
      slow = create_recipe(title: "Slow", ingredients: [ "chicken" ], prep_time: 40, cook_time: 20)
      quick = create_recipe(title: "Quick", ingredients: [ "chicken" ], prep_time: 5, cook_time: 5)

      expect(described_class.search("chicken").map(&:recipe)).to eq([ quick, slow ])
    end

    it "ranks unknown times after recipes with a total time" do
      unknown = create_recipe(title: "Unknown", ingredients: [ "chicken" ], prep_time: 0, cook_time: 0)
      timed = create_recipe(title: "Timed", ingredients: [ "chicken" ], prep_time: 30, cook_time: 0)

      expect(described_class.search("chicken").map(&:recipe)).to eq([ timed, unknown ])
    end

    it "caps cook-now recipes at 9 and does not pad with weaker matches" do
      10.times { |i|
        create_recipe(title: "Chicken #{i}", ingredients: [ "chicken" ], prep_time: i + 1, cook_time: 0)
      }
      create_recipe(title: "Almost", ingredients: [ "chicken", "onion" ], prep_time: 1, cook_time: 0)

      results = described_class.search("chicken")

      expect(results.size).to eq(9)
      expect(results).to all(be_cook_now)
      expect(results.map { |row| row.recipe.title }).not_to include("Almost")
    end

    it "fills leftover slots with almost-ready recipes up to 9" do
      create_recipe(title: "Exact", ingredients: [ "chicken" ], prep_time: 1, cook_time: 0)
      10.times { |i|
        create_recipe(title: "Almost #{i}", ingredients: [ "chicken", "onion" ], prep_time: i + 1, cook_time: 0)
      }
      create_recipe(title: "Far", ingredients: [ "chicken", "onion", "garlic", "ginger", "cream" ])

      results = described_class.search("chicken")

      expect(results.count(&:cook_now?)).to eq(1)
      expect(results.count(&:almost?)).to eq(8)
      expect(results.size).to eq(9)
      expect(results.map { |row| row.recipe.title }).not_to include("Far")
    end

    it "includes recipes missing 3 and skips those missing 4 or more" do
      close = create_recipe(title: "Close", ingredients: [ "chicken", "onion", "garlic", "ginger" ])
      create_recipe(title: "Far", ingredients: [ "chicken", "onion", "garlic", "ginger", "cream" ])

      results = described_class.search("chicken")

      expect(results.map(&:recipe)).to eq([ close ])
      expect(results.first.missing_count).to eq(3)
      expect(results.first).to be_almost
    end

    it "flags leftover catalog hits when nothing is within 3 missing" do
      create_recipe(
        title: "Stew",
        ingredients: [ "tomato", "beef", "onion", "carrot", "celery" ]
      )

      search = described_class.search("tomato")

      expect(search).to be_empty
      expect(search).to be_too_far
    end

    it "does not flag too_far when the exact pantry name is absent" do
      create_recipe(title: "Omelette", ingredients: [ "egg" ])

      search = described_class.search("chicken")

      expect(search).to be_empty
      expect(search).not_to be_too_far
    end

    it "splits pantry terms on commas or newlines" do
      recipe = create_recipe(title: "Stir fry", ingredients: [ "chicken", "onion" ])

      expect(described_class.search("chicken\nonion").map(&:recipe)).to eq([ recipe ])
    end

    it "exposes unique normalized pantry terms" do
      expect(described_class.search("tomato, tomatoes\nbeef").terms).to eq([ "tomato", "beef" ])
      expect(described_class.search("salt").terms).to eq([ "salt" ])
    end

    it "does not pad a small Cook now set" do
      create_recipe(title: "Exact", ingredients: [ "chicken" ])

      expect(described_class.search("chicken").map { |row| row.recipe.title }).to eq([ "Exact" ])
    end

    it "treats a staples-only pantry as not a match query" do
      expect(described_class.search("salt")).to be_staples_only
      expect(described_class.search("black pepper, water")).to be_staples_only
      expect(described_class.search("chicken")).not_to be_staples_only
      expect(described_class.search("")).not_to be_staples_only
    end

    it "keeps a hard cap of 9 when mixing cook-now and almost-ready recipes" do
      6.times { |i|
        create_recipe(title: "Exact #{i}", ingredients: [ "chicken" ], prep_time: i + 1, cook_time: 0)
      }
      5.times { |i|
        create_recipe(title: "Almost #{i}", ingredients: [ "chicken", "onion" ], prep_time: i + 1, cook_time: 0)
      }

      results = described_class.search("chicken")

      expect(results.count(&:cook_now?)).to eq(6)
      expect(results.count(&:almost?)).to eq(3)
      expect(results.size).to eq(9)
    end

    it "does not put a match count on result cards" do
      create_recipe(title: "Omelette", ingredients: [ "egg" ])
      create_recipe(title: "Stir fry", ingredients: [ "chicken", "onion", "garlic" ])

      expect(described_class.search("egg").first).not_to respond_to(:match_signal)
      expect(described_class.search("chicken").first.missing_count).to eq(2)
    end

    it "lists have and missing display text, with staples under have" do
      create_recipe(title: "Stir fry", ingredients: [ "chicken", "onion", "salt" ])

      result = described_class.search("chicken").first

      expect(result.have).to eq([ "chicken", "salt" ])
      expect(result.staples).to eq([ "salt" ])
      expect(result.missing).to eq([ "onion" ])
      expect(result).to be_almost
      expect(result).not_to be_cook_now
    end
  end

  describe ".explain" do
    it "returns nil when the pantry has no matchable ingredients" do
      recipe = create_recipe(title: "Omelette", ingredients: [ "egg" ])

      expect(described_class.explain(recipe, "")).to be_nil
      expect(described_class.explain(recipe, "salt")).to be_nil
    end

    it "explains have and missing for a recipe without ranking" do
      recipe = create_recipe(title: "Stir fry", ingredients: [ "chicken", "onion", "salt" ])

      result = described_class.explain(recipe, "chicken")

      expect(result.recipe).to eq(recipe)
      expect(result.missing_count).to eq(1)
      expect(result.have).to eq([ "chicken", "salt" ])
      expect(result.staples).to eq([ "salt" ])
      expect(result.missing).to eq([ "onion" ])
    end
  end
end
