require "rails_helper"

RSpec.describe "Recipes", type: :request do
  describe "GET /" do
    it "shows the pantry form" do
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("recipes.index.ingredients_label"))
      expect(response.body).to include(I18n.t("recipes.index.lead"))
      expect(response.body).not_to include("Salt, pepper, and water are assumed")
    end
  end

  describe "GET /recipes" do
    context "when the pantry matches recipes" do
      it "lists matching recipes with a cook-now signal" do
        recipe = create(:recipe, title: "Omelette", ingredients: [ "egg" ], image_url: "https://example.com/omelette.jpg")
        create(:recipe, title: "Steak", ingredients: [ "beef" ])

        get recipes_path, params: { ingredients: "egg" }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Omelette")
        expect(response.body).not_to include(">Cook now<")
        expect(response.body).to include(I18n.t("recipes.index.cook_now"))
        expect(response.body).to include(I18n.t("recipes.time.ready_in", count: 20))
        expect(response.body).to include(recipe_path(recipe, ingredients: "egg"))
        expect(response.body).to include(I18n.t("recipes.result.see_recipe"))
        expect(response.body).to include('class="recipe-card"')
        expect(response.body).to include('data-controller="recipe-photo"')
        expect(response.body).not_to include(I18n.t("recipes.show.extra_ingredients"))
        expect(response.body.scan("<h3>Omelette</h3>").size).to eq(1)
        expect(response.body.scan('class="recipe-card"').size).to eq(1)
        expect(response.body).not_to include("Steak")
      end

      it "groups exact matches under Cook now and near-misses under Almost" do
        create(:recipe, title: "Omelette", ingredients: [ "egg" ])
        create(:recipe, title: "Stir fry", ingredients: [ "chicken", "onion" ])
        create(:recipe, title: "Curry", ingredients: [ "chicken", "onion", "garlic", "ginger" ])
        create(:recipe, title: "Feast", ingredients: [ "chicken", "onion", "garlic", "ginger", "cream" ])

        get recipes_path, params: { ingredients: "egg, chicken" }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("<h2>#{I18n.t("recipes.index.cook_now")}</h2>")
        expect(response.body).to include("<h2>#{I18n.t("recipes.index.almost")}</h2>")
        expect(response.body).not_to include("<h2>Needs more</h2>")
        expect(response.body).to include("Omelette")
        expect(response.body).to include("Stir fry")
        expect(response.body).to include("Curry")
        expect(response.body).not_to include("Feast")
        expect(response.body).not_to include("Missing 1")
      end

      it "lists near matches with how many ingredients are missing" do
        create(:recipe, title: "Stir fry", ingredients: [ "chicken", "onion" ])

        get recipes_path, params: { ingredients: "chicken" }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Stir fry")
        expect(response.body).not_to include("Missing 1")
        expect(response.body).to include(I18n.t("recipes.result.extra_ingredients", list: "onion"))
        expect(response.body).to include("<h2>#{I18n.t("recipes.index.almost")}</h2>")
        expect(response.body).not_to include("Missing 1 to 3 ingredients.")
        expect(response.body).not_to include("<h2>#{I18n.t("recipes.index.cook_now")}</h2>")
      end

      it "lists pantry staples used by each result" do
        create(:recipe, title: "Omelette", ingredients: [ "egg", "salt" ])

        get recipes_path, params: { ingredients: "egg" }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t("recipes.result.pantry_staples", list: "salt"))
      end

      it "does not list Pet Treats or Pet Food recipes" do
        create(:recipe, title: "Omelette", ingredients: [ "egg" ])
        create(:recipe, title: "Dog biscuits", ingredients: [ "egg" ], category: "Pet Treats")
        create(:recipe, title: "Kibble loaf", ingredients: [ "egg" ], category: "Pet Food")

        get recipes_path, params: { ingredients: "egg" }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Omelette")
        expect(response.body).not_to include("Dog biscuits")
        expect(response.body).not_to include("Kibble loaf")
      end

      it "shows at most 9 cook-now recipes and skips weaker matches" do
        10.times { |i|
          create(:recipe, title: "Chicken #{i}", ingredients: [ "chicken" ], prep_time: i + 1, cook_time: 0)
        }
        create(:recipe, title: "Almost stew", ingredients: [ "chicken", "onion" ], prep_time: 1, cook_time: 0)

        get recipes_path, params: { ingredients: "chicken" }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("<h2>#{I18n.t("recipes.index.cook_now")}</h2>")
        expect(response.body).not_to include("<h2>#{I18n.t("recipes.index.almost")}</h2>")
        expect(response.body).not_to include("Almost stew")
        expect(response.body).not_to include("Chicken 9")
        expect(response.body).not_to include("Page ")
      end

      it "shows Time not listed and the No photo fallback when those are missing" do
        create(:recipe, title: "Omelette", ingredients: [ "egg" ], prep_time: 0, cook_time: 0)

        get recipes_path, params: { ingredients: "egg" }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t("recipes.time.unknown"))
        expect(response.body).to include("recipe-placeholder.svg")
        expect(response.body).not_to include("data-controller=\"recipe-photo\"")
      end
    end

    it "does not treat a staples-only pantry as a search" do
      create(:recipe, title: "Omelette", ingredients: [ "egg", "salt" ])

      get recipes_path, params: { ingredients: "salt" }

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include(I18n.t("recipes.index.empty.unknown", count: 1))
      expect(response.body).not_to include("Omelette")
      expect(response.body).not_to include("Cook now")
    end

    context "when nothing is close enough to cook" do
      it "shows an empty result when nothing matches" do
        create(:recipe, title: "Omelette", ingredients: [ "egg" ])

        get recipes_path, params: { ingredients: "chicken" }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t("recipes.index.empty.unknown", count: 1))
        expect(response.body).not_to include(I18n.t("recipes.index.empty.unknown", count: 2))
      end

      it "uses plural copy when several names are absent" do
        create(:recipe, title: "Omelette", ingredients: [ "egg" ])

        get recipes_path, params: { ingredients: "chicken, zucchini" }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t("recipes.index.empty.unknown", count: 2))
        expect(response.body).not_to include(I18n.t("recipes.index.empty.unknown", count: 1))
      end

      it "explains when matches exist but need more than three ingredients" do
        create(:recipe, title: "Stew", ingredients: [ "tomato", "beef", "onion", "carrot", "celery" ])

        get recipes_path, params: { ingredients: "tomato" }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t("recipes.index.empty.too_far", count: 1))
        expect(response.body).not_to include("these ingredients")
        expect(response.body).not_to include("Stew")
        expect(response.body).not_to include("See recipes")
        expect(response.body).not_to include(I18n.t("recipes.index.empty.unknown", count: 1))
        expect(response.body).not_to include("<h2>Needs more</h2>")
      end

      it "uses plural copy when several pantry terms still miss more than three" do
        create(:recipe,
          title: "Stew",
          ingredients: [ "tomato", "beef", "onion", "carrot", "celery", "cream" ]
        )

        get recipes_path, params: { ingredients: "tomato, beef" }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t("recipes.index.empty.too_far", count: 2))
        expect(response.body).not_to include("that ingredient")
        expect(response.body).not_to include("Stew")
      end
    end
  end

  describe "GET /recipes/:id" do
    context "when the recipe exists" do
      it "shows a recipe with times and pantry coverage" do
        recipe = create(:recipe,
          title: "Omelette",
          ingredients: [ "egg" ],
          prep_time: 5,
          cook_time: 10,
          image_url: "https://example.com/omelette.jpg",
          rating: 4.5
        )

        get recipe_path(recipe), params: { ingredients: "egg" }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Omelette")
        expect(response.body).to include(I18n.t("recipes.time.ready_in", count: 15))
        expect(response.body).to include(I18n.t("recipes.time.preparation", count: 5))
        expect(response.body).to include(I18n.t("recipes.time.cook", count: 10))
        expect(response.body).not_to include("Rated")
        expect(response.body).not_to include("4.5")
        expect(response.body).to include("egg")
        expect(response.body).to include("<h2>#{I18n.t("recipes.show.in_your_pantry")}</h2>")
        expect(response.body).not_to include("<h2>#{I18n.t("recipes.show.extra_ingredients")}</h2>")
        expect(response.body).not_to include(I18n.t("recipes.index.cook_now"))
        expect(response.body).to include(recipes_path(ingredients: "egg"))
        expect(response.body).to include(I18n.t("recipes.show.back"))
      end

      it "splits a recipe into have and missing pantry lists" do
        recipe = create(:recipe, title: "Stir fry", ingredients: [ "chicken", "onion", "salt" ])

        get recipe_path(recipe), params: { ingredients: "chicken" }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("<h2>#{I18n.t("recipes.show.in_your_pantry")}</h2>")
        expect(response.body).to include("<h2>#{I18n.t("recipes.show.extra_ingredients")}</h2>")
        expect(response.body).to include("chicken")
        expect(response.body).to include("salt")
        expect(response.body).to include("onion")
        expect(response.body).not_to include("<h2>Ingredients</h2>")
        expect(response.body).not_to include("You have everything — cook this now.")
      end

      it "shows the full ingredient list when there is no pantry query" do
        recipe = create(:recipe, title: "Omelette", ingredients: [ "egg" ])

        get recipe_path(recipe)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("<h2>#{I18n.t("recipes.show.extra_ingredients")}</h2>")
        expect(response.body).to include("egg")
        expect(response.body).not_to include("<h2>#{I18n.t("recipes.show.in_your_pantry")}</h2>")
        expect(response.body).to include(I18n.t("recipes.show.back"))
      end
    end

    it "returns not found when the recipe is missing" do
      get recipe_path(id: 0)

      expect(response).to have_http_status(:not_found)
    end
  end
end
