class Ingredient < ApplicationRecord
  has_many :recipe_ingredients, dependent: :restrict_with_exception
  has_many :recipes, through: :recipe_ingredients

  validates :name, :normalized_name, presence: true
  validates :normalized_name, uniqueness: true
end
