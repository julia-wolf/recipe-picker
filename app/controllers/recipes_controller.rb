class RecipesController < ApplicationController
  before_action :set_ingredients

  def index
    @search = RecipeMatcher.search(@ingredients)
  end

  def show
    @recipe = Recipe.includes(recipe_ingredients: :ingredient).find(params[:id])
    @explanation = RecipeMatcher.explain(@recipe, @ingredients)
  end

  private

  def set_ingredients
    @ingredients = params[:ingredients]
  end
end
