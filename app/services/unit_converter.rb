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
  # Limited to the 15 most frequent distinct names in our catalog (skipping the
  # compound "salt and ground black pepper to taste" row). tsp/tbsp scaled ×48
  # or ×16 when USDA lists no cup. First matching pattern wins.
  # fdcIds: vanilla 173471, baking powder 172804, baking soda 175040,
  # olive oil 171413, vegetable oil 172370, flour 169761, sugar 169655,
  # pepper 170931, cinnamon 171320, garlic 169230, butter 173430, milk 171265,
  # water 174158, egg 171287, salt 173468.
  GRAMS_PER_CUP = [
    [ /vanilla extract/, 208 ],
    [ /baking powder/, 220.8 ],
    [ /baking soda/, 220.8 ],
    [ /olive oil/, 216 ],
    [ /vegetable oil/, 218 ],
    [ /all purpose flour|\bflour\b/, 125 ],
    [ /white sugar|granulated sugar|(?<!brown )(?<!powdered )(?<!confectioner )(?<!icing )\bsugar\b/, 200 ],
    [ /black pepper/, 110.4 ],
    [ /ground cinnamon|\bcinnamon\b/, 124.8 ],
    [ /\bgarlic\b(?! powder)(?! salt)/, 136 ],
    [ /(?<!peanut )\bbutter\b/, 227 ],
    [ /(?<!coconut )\bmilk\b/, 244 ],
    [ /\bwater\b/, 237 ],
    [ /\begg\b/, 243 ],
    [ /\bsalt\b/, 292 ]
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
    (rounded % 1).zero? ? rounded.to_i.to_s : rounded.to_s
  end
end
