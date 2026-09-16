class IngredientNormalizer
  LEADING_AMOUNT = /\A\d+(?:[.,]\d+)?\s*/

  def self.call(name)
    name.to_s.downcase.gsub(/[^a-z0-9]+/, " ").squish.singularize
  end

  def self.pantry(term)
    call(term.to_s.sub(LEADING_AMOUNT, ""))
  end
end
