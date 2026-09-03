class Recipe < ApplicationRecord
  has_many :recipe_ingredients, dependent: :destroy
  has_many :ingredients, through: :recipe_ingredients

  validates :title, presence: true

  def total_time
    prep = prep_time.to_i
    cook = cook_time.to_i
    return nil if prep.zero? && cook.zero?

    prep + cook
  end
end
