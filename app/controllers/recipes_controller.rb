class RecipesController < ApplicationController
  def index
    @query = params[:q]
    @staples_only = RecipeMatcher.staples_only?(@query)
    @results = RecipeMatcher.search(@query, page: params[:page])
  end

  def show
    @query = params[:q]
    @recipe = Recipe.includes(recipe_ingredients: :ingredient).find(params[:id])
  end
end
