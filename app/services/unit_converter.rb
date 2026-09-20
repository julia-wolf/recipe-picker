class UnitConverter
  ML_PER_UNIT = {
    cup: 240,
    tablespoon: 15,
    teaspoon: 5,
    fluid_ounce: 30,
    pint: 473,
    quart: 946,
    gallon: 3785,
    milliliter: 1,
    liter: 1000
  }.freeze

  G_PER_UNIT = {
    ounce: 28,
    pound: 454,
    gram: 1,
    kilogram: 1000
  }.freeze

  # USDA FoodData Central SR Legacy household weights, grams per 240 ml cup.
  # Top 15 dry/solid catalog names — oils and other liquids stay ml. tsp/tbsp
  # scaled ×48 or ×16 when USDA lists no cup. First matching pattern wins.
  # fdcIds: baking powder 172804, baking soda 175040, garlic powder 171325,
  # brown sugar 168833, powdered sugar 169656, flour 169761, sugar 169655,
  # pepper 170931, cinnamon 171320, garlic 169230, butter 173430, salt 173468,
  # cumin 170923, yeast 175043, oats 173904.
  GRAMS_PER_CUP = [
    [ /baking powder/, 220.8 ],
    [ /baking soda/, 220.8 ],
    [ /garlic powder/, 148.8 ],
    [ /brown sugar/, 220 ],
    [ /confectioner sugar|powdered sugar|icing sugar/, 120 ],
    [ /all purpose flour|\bflour\b/, 125 ],
    [ /white sugar|granulated sugar|(?<!brown )(?<!powdered )(?<!confectioner )(?<!icing )\bsugar\b/, 200 ],
    [ /black pepper/, 110.4 ],
    [ /ground cinnamon|\bcinnamon\b/, 124.8 ],
    [ /\bgarlic\b(?! powder)(?! salt)/, 136 ],
    [ /(?<!peanut )\bbutter\b/, 227 ],
    [ /\bsalt\b/, 292 ],
    [ /ground cumin|\bcumin\b/, 100.8 ],
    [ /active dry yeast|\byeast\b/, 192 ],
    [ /\boats?\b/, 81 ]
  ].freeze

  def self.display_text(parsed)
    new(parsed).display_text
  end

  def initialize(parsed)
    @parsed = parsed
  end

  def display_text
    return @parsed.raw.to_s.strip if @parsed.quantity.nil?

    if (grams = to_g_from_density)
      "#{format_amount(grams)} g #{@parsed.name}".strip
    elsif (ml = to_ml)
      "#{format_amount(ml)} ml #{@parsed.name}".strip
    elsif (grams = to_g)
      "#{format_amount(grams)} g #{@parsed.name}".strip
    elsif @parsed.unit.nil?
      "#{format_amount(@parsed.quantity)} #{@parsed.name}".strip
    else
      @parsed.raw.to_s.strip
    end
  end

  private

  def to_g_from_density
    ml = to_ml
    per_cup = grams_per_cup
    ml && per_cup && ml * per_cup / ML_PER_UNIT[:cup].to_f
  end

  def grams_per_cup
    name = IngredientNormalizer.call(@parsed.name)
    GRAMS_PER_CUP.each { |pattern, grams| return grams if name.match?(pattern) }
    nil
  end

  def to_ml
    factor = ML_PER_UNIT[@parsed.unit]
    @parsed.quantity.to_f * factor if factor
  end

  def to_g
    factor = G_PER_UNIT[@parsed.unit]
    @parsed.quantity.to_f * factor if factor
  end

  def format_amount(value)
    rounded = value.round(1)
    if (rounded % 1).zero?
      rounded.to_i.to_s
    else
      rounded.to_s.tr(".", ",")
    end
  end
end
