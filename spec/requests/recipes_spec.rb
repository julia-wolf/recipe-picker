require "rails_helper"

RSpec.describe "Recipes", type: :request do
  def create_recipe(title:, ingredients:, prep_time: 10, cook_time: 10, image_url: nil, rating: nil)
    recipe = Recipe.create!(
      title: title,
      prep_time: prep_time,
      cook_time: cook_time,
      image_url: image_url,
      rating: rating
    )
    ingredients.each { |name| add_ingredient(recipe, name) }
    recipe
  end

  def add_ingredient(recipe, name)
    ingredient = Ingredient.find_or_create_by!(normalized_name: IngredientNormalizer.call(name)) do |record|
      record.name = name
    end
    recipe.recipe_ingredients.create!(ingredient: ingredient, display_text: name)
  end

  def browser_get(path, **params)
    get path, params: params, headers: {
      "HTTP_USER_AGENT" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    }
  end

  def t(key, **options)
    I18n.t(key, **options)
  end

  it "shows the pantry form on the home page" do
    browser_get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(t("recipes.index.ingredients_label"))
    expect(response.body).to include(t("recipes.index.lead"))
    expect(response.body).not_to include("Salt, pepper, and water are assumed")
  end

  it "lists matching recipes with a cook-now signal" do
    recipe = create_recipe(title: "Omelette", ingredients: [ "egg" ], image_url: "https://example.com/omelette.jpg")
    create_recipe(title: "Steak", ingredients: [ "beef" ])

    browser_get recipes_path, ingredients: "egg"

    expect(response.body).to include("Omelette")
    expect(response.body).not_to include(">Cook now<")
    expect(response.body).to include(t("recipes.index.cook_now"))
    expect(response.body).to include(t("recipes.time.ready_in", count: 20))
    expect(response.body).to include(recipe_path(recipe, ingredients: "egg"))
    expect(response.body).to include(t("recipes.result.see_recipe"))
    expect(response.body).to include('class="recipe-card"')
    expect(response.body).to include('data-controller="recipe-photo"')
    expect(response.body).not_to include(t("recipes.show.extra_ingredients"))
    expect(response.body.scan("<h3>Omelette</h3>").size).to eq(1)
    expect(response.body.scan('class="recipe-card"').size).to eq(1)
    expect(response.body).not_to include("Steak")
  end

  it "groups exact matches under Cook now and near-misses under Almost" do
    create_recipe(title: "Omelette", ingredients: [ "egg" ])
    create_recipe(title: "Stir fry", ingredients: [ "chicken", "onion" ])
    create_recipe(title: "Curry", ingredients: [ "chicken", "onion", "garlic", "ginger" ])
    create_recipe(title: "Feast", ingredients: [ "chicken", "onion", "garlic", "ginger", "cream" ])

    browser_get recipes_path, ingredients: "egg, chicken"

    expect(response.body).to include("<h2>#{t("recipes.index.cook_now")}</h2>")
    expect(response.body).to include("<h2>#{t("recipes.index.almost")}</h2>")
    expect(response.body).not_to include("<h2>Needs more</h2>")
    expect(response.body).to include("Omelette")
    expect(response.body).to include("Stir fry")
    expect(response.body).to include("Curry")
    expect(response.body).not_to include("Feast")
    expect(response.body).not_to include("Missing 1")
  end

  it "lists near matches with how many ingredients are missing" do
    create_recipe(title: "Stir fry", ingredients: [ "chicken", "onion" ])

    browser_get recipes_path, ingredients: "chicken"

    expect(response.body).to include("Stir fry")
    expect(response.body).not_to include("Missing 1")
    expect(response.body).to include(t("recipes.result.extra_ingredients", list: "onion"))
    expect(response.body).to include("<h2>#{t("recipes.index.almost")}</h2>")
    expect(response.body).not_to include("Missing 1 to 3 ingredients.")
    expect(response.body).not_to include("<h2>#{t("recipes.index.cook_now")}</h2>")
  end

  it "lists pantry staples used by each result" do
    create_recipe(title: "Omelette", ingredients: [ "egg", "salt" ])

    browser_get recipes_path, ingredients: "egg"

    expect(response.body).to include(t("recipes.result.pantry_staples", list: "salt"))
  end

  it "does not list Pet Treats or Pet Food recipes" do
    create_recipe(title: "Omelette", ingredients: [ "egg" ])
    treats = create_recipe(title: "Dog biscuits", ingredients: [ "egg" ])
    treats.update!(category: "Pet Treats")
    kibble = create_recipe(title: "Kibble loaf", ingredients: [ "egg" ])
    kibble.update!(category: "Pet Food")

    browser_get recipes_path, ingredients: "egg"

    expect(response.body).to include("Omelette")
    expect(response.body).not_to include("Dog biscuits")
    expect(response.body).not_to include("Kibble loaf")
  end

  it "does not treat staples alone as a pantry search" do
    create_recipe(title: "Omelette", ingredients: [ "egg", "salt" ])

    browser_get recipes_path, ingredients: "salt"

    expect(response.body).not_to include(t("recipes.index.empty.unknown", count: 1))
    expect(response.body).not_to include("Omelette")
    expect(response.body).not_to include("Cook now")
  end

  it "shows at most 9 cook-now recipes and skips weaker matches" do
    10.times { |i|
      create_recipe(title: "Chicken #{i}", ingredients: [ "chicken" ], prep_time: i + 1, cook_time: 0)
    }
    create_recipe(title: "Almost stew", ingredients: [ "chicken", "onion" ], prep_time: 1, cook_time: 0)

    browser_get recipes_path, ingredients: "chicken"

    expect(response.body).to include("<h2>#{t("recipes.index.cook_now")}</h2>")
    expect(response.body).not_to include("<h2>#{t("recipes.index.almost")}</h2>")
    expect(response.body).not_to include("Almost stew")
    expect(response.body).not_to include("Chicken 9")
    expect(response.body).not_to include("Page ")
  end

  it "shows an empty result when nothing matches" do
    create_recipe(title: "Omelette", ingredients: [ "egg" ])

    browser_get recipes_path, ingredients: "chicken"

    expect(response.body).to include(t("recipes.index.empty.unknown", count: 1))
    expect(response.body).not_to include(t("recipes.index.empty.unknown", count: 2))
  end

  it "uses plural copy when several names are absent" do
    create_recipe(title: "Omelette", ingredients: [ "egg" ])

    browser_get recipes_path, ingredients: "chicken, zucchini"

    expect(response.body).to include(t("recipes.index.empty.unknown", count: 2))
    expect(response.body).not_to include(t("recipes.index.empty.unknown", count: 1))
  end

  it "explains when matches exist but need more than three ingredients" do
    create_recipe(title: "Stew", ingredients: [ "tomato", "beef", "onion", "carrot", "celery" ])

    browser_get recipes_path, ingredients: "tomato"

    expect(response.body).to include(t("recipes.index.empty.too_far", count: 1))
    expect(response.body).not_to include("these ingredients")
    expect(response.body).not_to include("Stew")
    expect(response.body).not_to include("See recipes")
    expect(response.body).not_to include(t("recipes.index.empty.unknown", count: 1))
    expect(response.body).not_to include("<h2>Needs more</h2>")
  end

  it "uses plural copy when several pantry terms still miss more than three" do
    create_recipe(
      title: "Stew",
      ingredients: [ "tomato", "beef", "onion", "carrot", "celery", "cream" ]
    )

    browser_get recipes_path, ingredients: "tomato, beef"

    expect(response.body).to include(t("recipes.index.empty.too_far", count: 2))
    expect(response.body).not_to include("that ingredient")
    expect(response.body).not_to include("Stew")
  end

  it "shows a recipe with times and pantry coverage" do
    recipe = create_recipe(
      title: "Omelette",
      ingredients: [ "egg" ],
      prep_time: 5,
      cook_time: 10,
      image_url: "https://example.com/omelette.jpg",
      rating: 4.5
    )

    browser_get recipe_path(recipe), ingredients: "egg"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Omelette")
    expect(response.body).to include(t("recipes.time.ready_in", count: 15))
    expect(response.body).to include(t("recipes.time.preparation", count: 5))
    expect(response.body).to include(t("recipes.time.cook", count: 10))
    expect(response.body).not_to include("Rated")
    expect(response.body).not_to include("4.5")
    expect(response.body).to include("egg")
    expect(response.body).to include("<h2>#{t("recipes.show.in_your_pantry")}</h2>")
    expect(response.body).to include("egg")
    expect(response.body).not_to include("<h2>#{t("recipes.show.extra_ingredients")}</h2>")
    expect(response.body).not_to include(t("recipes.index.cook_now"))
    expect(response.body).to include(recipes_path(ingredients: "egg"))
    expect(response.body).to include(t("recipes.show.back"))
  end

  it "splits a recipe into have and missing pantry lists" do
    recipe = create_recipe(title: "Stir fry", ingredients: [ "chicken", "onion", "salt" ])

    browser_get recipe_path(recipe), ingredients: "chicken"

    expect(response.body).to include("<h2>#{t("recipes.show.in_your_pantry")}</h2>")
    expect(response.body).to include("<h2>#{t("recipes.show.extra_ingredients")}</h2>")
    expect(response.body).to include("chicken")
    expect(response.body).to include("salt")
    expect(response.body).to include("onion")
    expect(response.body).not_to include("<h2>Ingredients</h2>")
    expect(response.body).not_to include("You have everything — cook this now.")
  end

  it "shows Time not listed and the No photo fallback when those are missing" do
    create_recipe(title: "Omelette", ingredients: [ "egg" ], prep_time: 0, cook_time: 0)

    browser_get recipes_path, ingredients: "egg"

    expect(response.body).to include(t("recipes.time.unknown"))
    expect(response.body).to include("recipe-placeholder.svg")
    expect(response.body).not_to include("data-controller=\"recipe-photo\"")
  end

  it "shows the full ingredient list when there is no pantry query" do
    recipe = create_recipe(title: "Omelette", ingredients: [ "egg" ])

    browser_get recipe_path(recipe)

    expect(response.body).to include("<h2>#{t("recipes.show.extra_ingredients")}</h2>")
    expect(response.body).to include("egg")
    expect(response.body).not_to include("<h2>#{t("recipes.show.in_your_pantry")}</h2>")
    expect(response.body).to include(t("recipes.show.back"))
  end

  it "returns not found for a missing recipe" do
    browser_get recipe_path(id: 0)

    expect(response).to have_http_status(:not_found)
  end
end
