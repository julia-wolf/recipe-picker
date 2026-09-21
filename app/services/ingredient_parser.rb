class IngredientParser
  Result = Struct.new(:quantity, :unit, :name, :raw, keyword_init: true)
  CONTAINER_WORDS = /\A(?:cans?|packages?|jars?|bottles?|envelopes?)\s+/i

  class << self
    def parse(raw)
      raw = raw.to_s
      rest = raw.strip
      quantity, rest = Quantity.extract(rest)
      quantity, unit, rest = extract_parenthetical_size(quantity, rest)
      unit, rest = Units.extract(rest) if unit.nil?
      name = rest.sub(/\Aof\s+/i, "").strip
      name = raw.strip if name.empty?

      Result.new(quantity: quantity, unit: unit, name: name, raw: raw)
    end

    private

    def extract_parenthetical_size(quantity, text)
      match = text.match(/\A\(([^)]+)\)\s*/)
      return [ quantity, nil, text ] unless match

      inner_quantity, inner_rest = Quantity.extract(match[1].strip)
      inner_unit, = Units.extract(inner_rest)
      rest = match.post_match.sub(CONTAINER_WORDS, "")

      if inner_quantity && inner_unit
        [ inner_quantity, inner_unit, rest ]
      else
        [ quantity, nil, rest ]
      end
    end
  end
end
