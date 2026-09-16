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

  it "shows the pantry form on the home page" do
    browser_get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Ingredients you have")
    expect(response.body).to include("Enter pantry ingredients")
  end

  it "lists matching recipes with a cook-now signal" do
    recipe = create_recipe(title: "Omelette", ingredients: [ "egg" ], image_url: "https://example.com/omelette.jpg")
    create_recipe(title: "Steak", ingredients: [ "beef" ])

    browser_get recipes_path, q: "egg"

    expect(response.body).to include("Omelette")
    expect(response.body).to include("Cook now")
    expect(response.body).to include("20 min")
    expect(response.body).to include(recipe_path(recipe, q: "egg"))
    expect(response.body).not_to include("Steak")
  end

  it "lists near matches with how many ingredients are missing" do
    create_recipe(title: "Stir fry", ingredients: [ "chicken", "onion" ])

    browser_get recipes_path, q: "chicken"

    expect(response.body).to include("Stir fry")
    expect(response.body).to include("Missing 1")
  end

  it "explains that staples alone are not a pantry search" do
    create_recipe(title: "Omelette", ingredients: [ "egg", "salt" ])

    browser_get recipes_path, q: "salt"

    expect(response.body).to include("Salt, pepper, water, and black pepper are assumed")
    expect(response.body).not_to include("No recipes match those ingredients")
    expect(response.body).not_to include("Omelette")
  end

  it "shows an empty result when nothing matches" do
    create_recipe(title: "Omelette", ingredients: [ "egg" ])

    browser_get recipes_path, q: "chicken"

    expect(response.body).to include("No recipes match those ingredients")
  end

  it "shows a recipe with times, rating, and ingredients" do
    recipe = create_recipe(
      title: "Omelette",
      ingredients: [ "egg" ],
      prep_time: 5,
      cook_time: 10,
      image_url: "https://example.com/omelette.jpg",
      rating: 4.5
    )

    browser_get recipe_path(recipe), q: "egg"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Omelette")
    expect(response.body).to include("15 min total")
    expect(response.body).to include("prep 5 min")
    expect(response.body).to include("cook 10 min")
    expect(response.body).to include("Rating 4.5")
    expect(response.body).to include("egg")
    expect(response.body).to include(recipes_path(q: "egg"))
  end

  it "returns not found for a missing recipe" do
    browser_get recipe_path(id: 0)

    expect(response).to have_http_status(:not_found)
  end
end
