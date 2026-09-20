require "rails_helper"

RSpec.describe Recipe do
  it "has no total time when prep and cook are both zero" do
    recipe = described_class.new(title: "Omelette", prep_time: 0, cook_time: 0)

    expect(recipe.total_time).to be_nil
  end

  it "adds prep and cook for ranking and display" do
    recipe = described_class.new(title: "Omelette", prep_time: 5, cook_time: 10)

    expect(recipe.total_time).to eq(15)
  end
end
