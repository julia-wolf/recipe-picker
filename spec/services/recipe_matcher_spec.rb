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

      expect(described_class.search("")).to eq([])
      expect(described_class.search("   ")).to eq([])
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

    it "treats a staples-only pantry as not a match query" do
      expect(described_class).to be_staples_only("salt")
      expect(described_class).to be_staples_only("black pepper, water")
      expect(described_class).not_to be_staples_only("chicken")
      expect(described_class).not_to be_staples_only("")
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

    it "returns at most 20 recipes per page" do
      21.times { |i|
        create_recipe(title: "Chicken #{i}", ingredients: [ "chicken" ], prep_time: i + 1, cook_time: 0)
      }

      expect(described_class.search("chicken").size).to eq(20)
    end

    it "returns later ranked recipes on the next page" do
      recipes = 21.times.map { |i|
        create_recipe(title: "Chicken #{i}", ingredients: [ "chicken" ], prep_time: i + 1, cook_time: 0)
      }

      expect(described_class.search("chicken", page: 2).map(&:recipe)).to eq([ recipes.last ])
    end

    it "signals when another page of matches exists" do
      21.times { |i|
        create_recipe(title: "Chicken #{i}", ingredients: [ "chicken" ], prep_time: i + 1, cook_time: 0)
      }

      expect(described_class.search("chicken")).to be_has_next
      expect(described_class.search("chicken", page: 2)).not_to be_has_next
    end

    it "treats invalid pages as the first page" do
      first = create_recipe(title: "First", ingredients: [ "chicken" ], prep_time: 5, cook_time: 0)
      create_recipe(title: "Second", ingredients: [ "chicken" ], prep_time: 50, cook_time: 0)

      expect(described_class.search("chicken", page: 0).map(&:recipe).first).to eq(first)
      expect(described_class.search("chicken", page: -1).map(&:recipe).first).to eq(first)
    end
  end
end
