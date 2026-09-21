FactoryBot.define do
  factory :recipe do
    sequence(:title) { |n| "Recipe #{n}" }
    prep_time { 10 }
    cook_time { 10 }

    transient do
      ingredients { [] }
    end

    after(:create) do |recipe, evaluator|
      evaluator.ingredients.each do |name|
        ingredient = Ingredient.find_or_create_by!(normalized_name: IngredientNormalizer.normalize(name)) do |record|
          record.name = name
        end
        recipe.recipe_ingredients.create!(ingredient: ingredient, display_text: name)
      end
    end
  end
end
