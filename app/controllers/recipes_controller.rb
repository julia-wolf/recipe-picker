class RecipesController < ApplicationController
  def index
    @ingredients = params[:ingredients]
    @staples_only = RecipeMatcher.staples_only?(@ingredients)
    @results = RecipeMatcher.search(@ingredients, page: params[:page])
  end

  def show
    @ingredients = params[:ingredients]
    @recipe = Recipe.includes(recipe_ingredients: :ingredient).find(params[:id])
  end
end
