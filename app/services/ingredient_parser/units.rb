class IngredientParser
  class Units
    ALIASES = {
      "fluid ounce" => :fluid_ounce,
      "fl. oz." => :fluid_ounce,
      "fl oz" => :fluid_ounce,
      "tablespoon" => :tablespoon,
      "tbsp" => :tablespoon,
      "teaspoon" => :teaspoon,
      "tsp" => :teaspoon,
      "millilitre" => :milliliter,
      "milliliter" => :milliliter,
      "litre" => :liter,
      "liter" => :liter,
      "quart" => :quart,
      "pint" => :pint,
      "gallon" => :gallon,
      "cup" => :cup,
      "ounce" => :ounce,
      "pound" => :pound,
      "gram" => :gram,
      "kilogram" => :kilogram,
      "lb" => :pound,
      "oz" => :ounce,
      "ml" => :milliliter,
      "l" => :liter,
      "kg" => :kilogram,
      "g" => :gram
    }.freeze

    class << self
      def extract(text)
        ALIASES.each do |alias_name, unit|
          remainder = text.sub(/\A#{Regexp.escape(alias_name)}s?\b\.?\s*/i, "")
          return [ unit, remainder ] unless remainder == text
        end

        [ nil, text ]
      end
    end
  end
end
