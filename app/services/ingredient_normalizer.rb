class IngredientNormalizer
  class << self
    def normalize(name)
      name.to_s.downcase.gsub(/[^a-z0-9]+/, " ").squish.singularize
    end

    def without_amount(term)
      normalize(term.to_s.sub(/\A\d+(?:[.,]\d+)?\s*/, ""))
    end
  end
end
