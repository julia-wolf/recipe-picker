class IngredientParser
  Result = Struct.new(:quantity, :unit, :name, :raw, keyword_init: true)

  UNICODE_FRACTIONS = {
    "½" => 1/2r,
    "¼" => 1/4r,
    "¾" => 3/4r,
    "⅓" => 1/3r,
    "⅔" => 2/3r,
    "⅛" => 1/8r,
    "⅜" => 3/8r,
    "⅝" => 5/8r,
    "⅞" => 7/8r
  }.freeze

  UNIT_ALIASES = [
    [ "fluid ounces", :fluid_ounce ],
    [ "fluid ounce", :fluid_ounce ],
    [ "fl. oz.", :fluid_ounce ],
    [ "fl oz", :fluid_ounce ],
    [ "tablespoons", :tablespoon ],
    [ "tablespoon", :tablespoon ],
    [ "tbsps", :tablespoon ],
    [ "tbsp", :tablespoon ],
    [ "teaspoons", :teaspoon ],
    [ "teaspoon", :teaspoon ],
    [ "tsps", :teaspoon ],
    [ "tsp", :teaspoon ],
    [ "milliliters", :milliliter ],
    [ "millilitre", :milliliter ],
    [ "milliliter", :milliliter ],
    [ "liters", :liter ],
    [ "litres", :liter ],
    [ "liter", :liter ],
    [ "litre", :liter ],
    [ "quarts", :quart ],
    [ "quart", :quart ],
    [ "pints", :pint ],
    [ "pint", :pint ],
    [ "gallons", :gallon ],
    [ "gallon", :gallon ],
    [ "cups", :cup ],
    [ "cup", :cup ],
    [ "ounces", :ounce ],
    [ "ounce", :ounce ],
    [ "pounds", :pound ],
    [ "pound", :pound ],
    [ "grams", :gram ],
    [ "gram", :gram ],
    [ "kilograms", :kilogram ],
    [ "kilogram", :kilogram ],
    [ "lbs", :pound ],
    [ "lb", :pound ],
    [ "oz", :ounce ],
    [ "ml", :milliliter ],
    [ "l", :liter ],
    [ "kg", :kilogram ],
    [ "g", :gram ]
  ].freeze

  CONTAINER_WORDS = /\A(?:cans?|packages?|jars?|bottles?|envelopes?)\s+/i
  FRACTION_CHARS = UNICODE_FRACTIONS.keys.map { |char| Regexp.escape(char) }.join
  QUANTITY_PATTERN = /
    \A
    (?:
      (\d+)\s+(\d+)\s*[\/\u2044]\s*(\d+)
      |
      (\d+)\s+([#{FRACTION_CHARS}])
      |
      (\d+)\s*[\/\u2044]\s*(\d+)
      |
      ([#{FRACTION_CHARS}])
      |
      (\d*\.\d+|\d+)
    )
    \s*
  /x

  def self.parse(raw)
    new(raw).parse
  end

  def initialize(raw)
    @raw = raw.to_s
  end

  def parse
    rest = @raw.strip
    quantity, rest = extract_quantity(rest)
    quantity, unit, rest = extract_parenthetical_size(quantity, rest)
    unit, rest = extract_unit(rest) if unit.nil?
    name = rest.sub(/\Aof\s+/i, "").strip
    name = @raw.strip if name.empty?

    Result.new(quantity: quantity, unit: unit, name: name, raw: @raw)
  end

  private

  def extract_quantity(text)
    match = QUANTITY_PATTERN.match(text)
    return [ nil, text ] unless match

    quantity =
      if match[1]
        match[1].to_r + (match[2].to_r / match[3].to_r)
      elsif match[4]
        match[4].to_r + UNICODE_FRACTIONS.fetch(match[5])
      elsif match[6]
        match[6].to_r / match[7].to_r
      elsif match[8]
        UNICODE_FRACTIONS.fetch(match[8])
      else
        match[9].include?(".") ? match[9].to_f : match[9].to_r
      end

    [ quantity, match.post_match ]
  end

  def extract_parenthetical_size(quantity, text)
    match = text.match(/\A\(([^)]+)\)\s*/)
    return [ quantity, nil, text ] unless match

    inner_quantity, inner_rest = extract_quantity(match[1].strip)
    inner_unit, = extract_unit(inner_rest)
    rest = match.post_match.sub(CONTAINER_WORDS, "")

    if inner_quantity && inner_unit
      [ inner_quantity, inner_unit, rest ]
    else
      [ quantity, nil, rest ]
    end
  end

  def extract_unit(text)
    UNIT_ALIASES.each do |alias_name, unit|
      pattern = /\A#{Regexp.escape(alias_name)}\b\.?\s*/i
      return [ unit, text.sub(pattern, "") ] if text.match?(pattern)
    end

    [ nil, text ]
  end
end
