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

    expect(helper.recipe_time(recipe)).to eq("Time not listed")
  end

  it "joins detailed times with a middle dot" do
    recipe = Recipe.new(title: "Omelette", prep_time: 5, cook_time: 10)

    expect(helper.recipe_time(recipe, detail: true)).to eq("15 min total · prep 5 min · cook 10 min")
  end

  it "counts unique pantry entries after normalizing" do
    expect(helper.pantry_entry_count("tomato, tomatoes\nbeef")).to eq(2)
    expect(helper.pantry_entry_count("salt")).to eq(1)
  end
end
