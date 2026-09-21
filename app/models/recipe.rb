class Recipe < ApplicationRecord
  has_many :recipe_ingredients, dependent: :destroy
  has_many :ingredients, through: :recipe_ingredients

  validates :title, presence: true

  def total_time
    total = prep_time.to_i + cook_time.to_i
    total.positive? ? total : nil
  end
end
