require "rails_helper"

RSpec.describe RecipesController, type: :controller do
  describe "GET #index" do
    it "assigns a search for the pantry terms" do
      omelette = create(:recipe, title: "Omelette", ingredients: [ "egg" ])
      create(:recipe, title: "Steak", ingredients: [ "beef" ])

      get :index, params: { ingredients: "egg" }

      expect(controller.view_assigns["search"].map(&:recipe)).to eq([ omelette ])
    end
  end

  describe "GET #show" do
    it "assigns the recipe and pantry coverage" do
      recipe = create(:recipe, title: "Stir fry", ingredients: [ "chicken", "onion" ])

      get :show, params: { id: recipe, ingredients: "chicken" }

      expect(controller.view_assigns["recipe"]).to eq(recipe)
      expect(controller.view_assigns["coverage"].missing).to eq([ "onion" ])
    end

    it "raises ActiveRecord::RecordNotFound when the recipe is missing" do
      expect { get :show, params: { id: 0 } }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
