require "rails_helper"

RSpec.describe RecipeMatcher do
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
    context "when the pantry is blank" do
      before { create(:recipe, title: "Omelette", ingredients: [ "egg" ]) }

      it "returns no results and no match flags" do
        search = described_class.search("")

        expect(search).to be_empty
        expect(search).not_to be_needs_more
        expect(search).not_to be_staples_only
      end

      it "treats whitespace as blank" do
        expect(described_class.search("   ")).to be_empty
      end
    end

    it "does not treat a staples-only pantry as a match query" do
      expect(described_class.search("salt")).to be_staples_only
      expect(described_class.search("black pepper, water")).to be_staples_only
      expect(described_class.search("chicken")).not_to be_staples_only
      expect(described_class.search("")).not_to be_staples_only
    end

    context "when normalizing pantry terms" do
      it "normalizes pantry terms before matching" do
        recipe = create(:recipe, title: "Omelette", ingredients: [ "Egg" ])

        results = described_class.search("EGG")

        expect(results.map(&:recipe)).to eq([ recipe ])
        expect(results.first.missing_count).to eq(0)
      end

      it "matches ingredients only by exact normalized name" do
        exact = create(:recipe, title: "Flour mix", ingredients: [ "flour" ])
        create(:recipe, title: "Bread", ingredients: [ "all-purpose flour" ])

        expect(described_class.search("flour").map(&:recipe)).to eq([ exact ])
      end

      it "matches singular pantry terms to plural recipe ingredients" do
        recipe = create(:recipe, title: "Omelette", ingredients: [ "eggs" ])

        expect(described_class.search("egg").map(&:recipe)).to eq([ recipe ])
      end

      it "ignores a leading amount on a pantry term" do
        recipe = create(:recipe, title: "Omelette", ingredients: [ "eggs" ])

        expect(described_class.search("6 eggs").map(&:recipe)).to eq([ recipe ])
        expect(described_class.search("6eggs").map(&:recipe)).to eq([ recipe ])
      end

      it "splits pantry terms on commas or newlines" do
        recipe = create(:recipe, title: "Stir fry", ingredients: [ "chicken", "onion" ])

        expect(described_class.search("chicken\nonion").map(&:recipe)).to eq([ recipe ])
      end

      it "exposes unique normalized pantry terms" do
        expect(described_class.search("tomato, tomatoes\nbeef").pantry_terms).to eq([ "tomato", "beef" ])
        expect(described_class.search("salt").pantry_terms).to eq([ "salt" ])
      end
    end

    context "when a recipe line is a staple" do
      it "does not treat staples as a pantry match" do
        create(:recipe, title: "Salted chicken", ingredients: [ "chicken", "salt" ])
        create(:recipe, title: "Just salt", ingredients: [ "salt" ])

        expect(described_class.search("salt")).to be_empty
      end

      it "ignores black pepper as a staple phrase, not the word black" do
        peppered = create(:recipe, title: "Peppered chicken", ingredients: [ "chicken", "black pepper" ])
        inky = create(:recipe, title: "Squid ink", ingredients: [ "black" ])

        expect(described_class.search("black pepper")).to be_empty
        expect(described_class.search("black").map(&:recipe)).to eq([ inky ])
        expect(described_class.search("chicken").find { |row| row.recipe == peppered }.missing_count).to eq(0)
      end

      it "covers compound salt-and-pepper lines as staples" do
        recipe = create(:recipe,
          title: "Seasoned eggs",
          ingredients: [ "egg", "salt and ground black pepper to taste" ]
        )

        expect(described_class.search("egg").find { |row| row.recipe == recipe }).to have_attributes(
          missing_count: 0,
          missing: be_empty,
          have: include("salt and ground black pepper to taste"),
          staples: include("salt and ground black pepper to taste")
        )
      end

      it "does not treat garlic salt as a staple" do
        recipe = create(:recipe, title: "Seasoned eggs", ingredients: [ "egg", "garlic salt" ])

        expect(described_class.search("egg").find { |row| row.recipe == recipe }).to have_attributes(
          missing_count: 1,
          missing: include("garlic salt")
        )
      end

      it "treats water as a staple" do
        recipe = create(:recipe, title: "Boiled egg", ingredients: [ "egg", "water" ])

        expect(described_class.search("egg").find { |row| row.recipe == recipe }).to have_attributes(
          missing_count: 0,
          staples: include("water")
        )
      end

      it "does not treat bell pepper or cayenne as staples" do
        recipe = create(:recipe,
          title: "Peppers",
          ingredients: [ "egg", "green bell pepper chopped", "cayenne pepper" ]
        )

        expect(described_class.search("egg").find { |row| row.recipe == recipe }).to have_attributes(
          missing_count: 2,
          missing: include("green bell pepper chopped", "cayenne pepper")
        )
      end

      it "counts missing non-staple ingredients" do
        recipe = create(:recipe, title: "Stir fry", ingredients: [ "chicken", "onion", "salt" ])

        expect(described_class.search("chicken").find { |row| row.recipe == recipe }.missing_count).to eq(1)
      end

      it "lists have and missing display text, with staples under have" do
        create(:recipe, title: "Stir fry", ingredients: [ "chicken", "onion", "salt" ])

        result = described_class.search("chicken").first

        expect(result).to have_attributes(
          have: [ "chicken", "salt" ],
          staples: [ "salt" ],
          missing: [ "onion" ]
        )
        expect(result).to be_almost
        expect(result).not_to be_cook_now
      end

      it "does not put a match count on result cards" do
        create(:recipe, title: "Omelette", ingredients: [ "egg" ])
        create(:recipe, title: "Stir fry", ingredients: [ "chicken", "onion", "garlic" ])

        expect(described_class.search("egg").first).not_to respond_to(:match_signal)
        expect(described_class.search("chicken").first.missing_count).to eq(2)
      end
    end

    it "excludes Pet Treats and Pet Food from results" do
      dinner = create(:recipe, title: "Omelette", ingredients: [ "egg" ])
      create(:recipe, title: "Dog biscuits", ingredients: [ "egg" ], category: "Pet Treats")
      create(:recipe, title: "Kibble loaf", ingredients: [ "egg" ], category: "Pet Food")
      hot_dog = create(:recipe, title: "Fair hot dog", ingredients: [ "egg" ], category: "Hot Dogs and Corn Dogs")

      expect(described_class.search("egg").map(&:recipe)).to contain_exactly(dinner, hot_dog)
    end

    context "when ranking the decision set" do
      it "does not query once per recipe when scoring matches" do
        3.times { |i| create(:recipe, title: "Chicken #{i}", ingredients: [ "chicken", "onion" ]) }

        selects = count_selects { described_class.search("chicken") }

        expect(selects).to be <= 5
      end

      it "ranks fewer missing ingredients first" do
        almost = create(:recipe, title: "Almost", ingredients: [ "chicken", "onion" ])
        exact = create(:recipe, title: "Exact", ingredients: [ "chicken" ])

        expect(described_class.search("chicken").map(&:recipe)).to eq([ exact, almost ])
      end

      it "ranks shorter total time after equal missing counts" do
        slow = create(:recipe, title: "Slow", ingredients: [ "chicken" ], prep_time: 40, cook_time: 20)
        quick = create(:recipe, title: "Quick", ingredients: [ "chicken" ], prep_time: 5, cook_time: 5)

        expect(described_class.search("chicken").map(&:recipe)).to eq([ quick, slow ])
      end

      it "does not rank by rating" do
        slow_star = create(:recipe,
          title: "Slow star",
          ingredients: [ "chicken" ],
          prep_time: 40,
          cook_time: 20,
          rating: 5
        )
        quick = create(:recipe,
          title: "Quick",
          ingredients: [ "chicken" ],
          prep_time: 5,
          cook_time: 5,
          rating: 1
        )

        expect(described_class.search("chicken").map(&:recipe)).to eq([ quick, slow_star ])
      end

      it "ranks unknown times after recipes with a total time" do
        unknown = create(:recipe, title: "Unknown", ingredients: [ "chicken" ], prep_time: 0, cook_time: 0)
        timed = create(:recipe, title: "Timed", ingredients: [ "chicken" ], prep_time: 30, cook_time: 0)

        expect(described_class.search("chicken").map(&:recipe)).to eq([ timed, unknown ])
      end

      it "caps cook-now recipes at 9 and does not pad with weaker matches" do
        10.times { |i|
          create(:recipe, title: "Chicken #{i}", ingredients: [ "chicken" ], prep_time: i + 1, cook_time: 0)
        }
        create(:recipe, title: "Almost", ingredients: [ "chicken", "onion" ], prep_time: 1, cook_time: 0)

        results = described_class.search("chicken")

        expect(results.size).to eq(9)
        expect(results).to all(be_cook_now)
        expect(results.map { |row| row.recipe.title }).not_to include("Almost")
      end

      it "fills leftover slots with almost-ready recipes up to 9" do
        create(:recipe, title: "Exact", ingredients: [ "chicken" ], prep_time: 1, cook_time: 0)
        10.times { |i|
          create(:recipe, title: "Almost #{i}", ingredients: [ "chicken", "onion" ], prep_time: i + 1, cook_time: 0)
        }
        create(:recipe, title: "Far", ingredients: [ "chicken", "onion", "garlic", "ginger", "cream" ])

        results = described_class.search("chicken")

        expect(results.count(&:cook_now?)).to eq(1)
        expect(results.count(&:almost?)).to eq(8)
        expect(results.size).to eq(9)
        expect(results.map { |row| row.recipe.title }).not_to include("Far")
      end

      it "includes recipes missing 3 and skips those missing 4 or more" do
        close = create(:recipe, title: "Close", ingredients: [ "chicken", "onion", "garlic", "ginger" ])
        create(:recipe, title: "Far", ingredients: [ "chicken", "onion", "garlic", "ginger", "cream" ])

        results = described_class.search("chicken")

        expect(results.map(&:recipe)).to eq([ close ])
        expect(results.first).to have_attributes(missing_count: 3)
        expect(results.first).to be_almost
      end

      it "does not pad a small Cook now set" do
        create(:recipe, title: "Exact", ingredients: [ "chicken" ])

        expect(described_class.search("chicken").map { |row| row.recipe.title }).to eq([ "Exact" ])
      end

      it "keeps a hard cap of 9 when mixing cook-now and almost-ready recipes" do
        6.times { |i|
          create(:recipe, title: "Exact #{i}", ingredients: [ "chicken" ], prep_time: i + 1, cook_time: 0)
        }
        5.times { |i|
          create(:recipe, title: "Almost #{i}", ingredients: [ "chicken", "onion" ], prep_time: i + 1, cook_time: 0)
        }

        results = described_class.search("chicken")

        expect(results.count(&:cook_now?)).to eq(6)
        expect(results.count(&:almost?)).to eq(3)
        expect(results.size).to eq(9)
      end
    end

    context "when nothing is within three missing ingredients" do
      it "flags leftover catalog hits when nothing is within 3 missing" do
        create(:recipe,
          title: "Stew",
          ingredients: [ "tomato", "beef", "onion", "carrot", "celery" ]
        )

        expect(described_class.search("tomato")).to be_empty.and be_needs_more
      end

      it "does not flag needs_more when the exact pantry name is absent" do
        create(:recipe, title: "Omelette", ingredients: [ "egg" ])

        search = described_class.search("chicken")

        expect(search).to be_empty
        expect(search).not_to be_needs_more
      end
    end
  end

  describe ".coverage" do
    it "returns nil when the pantry has no matchable ingredients" do
      recipe = create(:recipe, title: "Omelette", ingredients: [ "egg" ])

      expect(described_class.coverage(recipe, "")).to be_nil
      expect(described_class.coverage(recipe, "salt")).to be_nil
    end

    it "returns have and missing without ranking" do
      recipe = create(:recipe, title: "Stir fry", ingredients: [ "chicken", "onion", "salt" ])

      expect(described_class.coverage(recipe, "chicken")).to have_attributes(
        recipe:,
        missing_count: 1,
        have: [ "chicken", "salt" ],
        staples: [ "salt" ],
        missing: [ "onion" ]
      )
    end
  end
end
