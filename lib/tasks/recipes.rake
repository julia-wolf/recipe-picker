namespace :recipes do
  desc "Import recipes from the Pennylane dataset URL"
  task import: :environment do
    RecipeImporter.import
    puts "Imported #{Recipe.count} recipes, #{Ingredient.count} ingredients."
  end
end
