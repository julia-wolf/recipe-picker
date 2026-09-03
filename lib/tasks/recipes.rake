namespace :recipes do
  desc "Import recipes from the Pennylane dataset URL, or a local JSON/gzip path"
  task :import, [ :source ] => :environment do |_task, args|
    source = args[:source].presence || RecipeImporter::DATASET_URL
    RecipeImporter.import(source)
    puts "Imported #{Recipe.count} recipes, #{Ingredient.count} ingredients."
  end
end
