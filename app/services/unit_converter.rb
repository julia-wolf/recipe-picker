class UnitConverter
  ML_PER_UNIT = {
    cup: 240,
    fluid_ounce: 30,
    pint: 473,
    quart: 946,
    gallon: 3785,
    milliliter: 1,
    liter: 1000
  }.freeze

  GRAMS_PER_UNIT = {
    ounce: 28,
    pound: 454,
    gram: 1,
    kilogram: 1000
  }.freeze

  GRAMS_PER_CUP = [
    [ /baking powder/, 220.8 ],
    [ /baking soda/, 220.8 ],
    [ /garlic powder/, 148.8 ],
    [ /brown sugar/, 220 ],
    [ /confectioners? sugar|powdered sugar|icing sugar/, 120 ],
    [ /all purpose flour|\bflour\b/, 125 ],
    [ /white sugar|granulated sugar|\bsugar\b/, 200 ],
    [ /black pepper/, 110.4 ],
    [ /ground cinnamon|\bcinnamon\b/, 124.8 ],
    [ /\bgarlic\b(?! powder)(?! salt)/, 136 ],
    [ /(?<!peanut )\bbutter\b/, 227 ],
    [ /\bsalt\b/, 292 ],
    [ /ground cumin|\bcumin\b/, 100.8 ],
    [ /active dry yeast|\byeast\b/, 192 ],
    [ /\boats?\b/, 81 ]
  ].freeze

  class << self
    def display_text(parsed)
      new(parsed).display_text
    end
  end

  def initialize(parsed)
    @parsed = parsed
  end

  def display_text
    return @parsed.raw.to_s.strip if @parsed.quantity.nil?

    if (grams = to_g_from_cup_weight)
      "#{format_grams(grams)} g #{@parsed.name}".strip
    elsif (ml = to_ml)
      "#{format_amount(ml)} ml #{@parsed.name}".strip
    elsif (grams = to_g)
      "#{format_grams(grams)} g #{@parsed.name}".strip
    elsif @parsed.unit.nil?
      "#{format_amount(@parsed.quantity)} #{@parsed.name}".strip
    else
      @parsed.raw.to_s.strip
    end
  end

  private

  def to_g_from_cup_weight
    return unless @parsed.unit == :cup

    ml = to_ml
    per_cup = grams_per_cup
    ml && per_cup && ml * per_cup / ML_PER_UNIT[:cup].to_f
  end

  def grams_per_cup
    name = IngredientNormalizer.normalize(@parsed.name)
    GRAMS_PER_CUP.find { |pattern,| name.match?(pattern) }&.last
  end

  def to_ml
    factor = ML_PER_UNIT[@parsed.unit]
    @parsed.quantity.to_f * factor if factor
  end

  def to_g
    factor = GRAMS_PER_UNIT[@parsed.unit]
    @parsed.quantity.to_f * factor if factor
  end

  def format_grams(value)
    value.round.to_i.to_s
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
