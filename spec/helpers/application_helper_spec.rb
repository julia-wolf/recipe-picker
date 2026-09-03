require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  it "uses the No photo fallback when a recipe has no image" do
    recipe = Recipe.new(title: "Omelette", image_url: nil)

    html = helper.recipe_photo_tag(recipe)

    expect(html).to include("recipe-placeholder.svg")
    expect(html).to include("alt=\"Omelette\"")
    expect(html).to include("this.onerror=null")
  end

  it "says Time not listed when prep and cook are both zero" do
    recipe = Recipe.new(title: "Omelette", prep_time: 0, cook_time: 0)

    expect(helper.recipe_time(recipe)).to eq("Ready in: time unknown")
  end

  it "spells out minutes on result cards" do
    recipe = Recipe.new(title: "Omelette", prep_time: 10, cook_time: 10)

    expect(helper.recipe_time(recipe)).to eq("Ready in: 20 minutes")
  end

  it "lists detailed times on separate lines" do
    recipe = Recipe.new(title: "Omelette", prep_time: 5, cook_time: 10)

    expect(helper.recipe_time_lines(recipe)).to eq(
      [
        "Ready in: 15 minutes",
        "Preparation: 5 minutes",
        "Cook time: 10 minutes"
      ]
    )
  end

  it "counts unique pantry entries after normalizing" do
    expect(helper.pantry_entry_count("tomato, tomatoes\nbeef")).to eq(2)
    expect(helper.pantry_entry_count("salt")).to eq(1)
  end
end
