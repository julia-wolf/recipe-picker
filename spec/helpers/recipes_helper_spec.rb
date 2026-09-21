require "rails_helper"

RSpec.describe RecipesHelper, type: :helper do
  it "uses the No photo fallback when a recipe has no image" do
    recipe = Recipe.new(title: "Omelette", image_url: nil)

    html = helper.recipe_photo_tag(recipe)

    expect(html).to include("recipe-placeholder.svg")
    expect(html).to include("alt=\"Omelette\"")
    expect(html).not_to include("data-controller")
  end

  it "uses a Stimulus fallback when the dataset photo URL 404s" do
    recipe = Recipe.new(title: "Omelette", image_url: "https://example.com/omelette.jpg")

    html = helper.recipe_photo_tag(recipe)

    expect(html).to include("data-controller=\"recipe-photo\"")
    expect(html).to include("recipe-photo#fallback")
    expect(html).to include("recipe-placeholder.svg")
  end

  it "says Time not listed when prep and cook are both zero" do
    recipe = Recipe.new(title: "Omelette", prep_time: 0, cook_time: 0)

    expect(helper.recipe_time(recipe)).to eq(I18n.t("recipes.time.unknown"))
  end

  it "spells out minutes on result cards" do
    recipe = Recipe.new(title: "Omelette", prep_time: 10, cook_time: 10)

    expect(helper.recipe_time(recipe)).to eq(I18n.t("recipes.time.ready_in", count: 20))
  end

  it "lists detailed times on separate lines" do
    recipe = Recipe.new(title: "Omelette", prep_time: 5, cook_time: 10)

    expect(helper.recipe_time_lines(recipe)).to eq(
      [
        I18n.t("recipes.time.ready_in", count: 15),
        I18n.t("recipes.time.preparation", count: 5),
        I18n.t("recipes.time.cook", count: 10)
      ]
    )
  end

  it "uses minute when the value is 1" do
    recipe = Recipe.new(title: "Omelette", prep_time: 1, cook_time: 0)

    expect(helper.recipe_time_lines(recipe)).to eq(
      [
        I18n.t("recipes.time.ready_in", count: 1),
        I18n.t("recipes.time.preparation", count: 1)
      ]
    )
  end
end
