require "rails_helper"

RSpec.describe IngredientParser do
  def parse(raw)
    described_class.parse(raw)
  end

  it "parses a simple cup measure" do
    result = parse("1 cup all-purpose flour")

    expect(result.quantity).to eq(1)
    expect(result.unit).to eq(:cup)
    expect(result.name).to eq("all-purpose flour")
    expect(result.raw).to eq("1 cup all-purpose flour")
  end

  it "parses mixed numbers with unicode fractions" do
    result = parse("1 ½ cups water")

    expect(result.quantity).to eq(3/2r)
    expect(result.unit).to eq(:cup)
    expect(result.name).to eq("water")
  end

  it "parses ascii mixed numbers" do
    result = parse("1 1/2 cups water")

    expect(result.quantity).to eq(3/2r)
    expect(result.unit).to eq(:cup)
  end

  it "parses a leading decimal without a zero" do
    result = parse(".666 cup milk")

    expect(result.quantity).to eq(0.666)
    expect(result.unit).to eq(:cup)
    expect(result.name).to eq("milk")
  end

  it "parses fractions that use a unicode fraction slash" do
    result = parse("11 \u204416 cups water")

    expect(result.quantity).to eq(11/16r)
    expect(result.unit).to eq(:cup)
    expect(result.name).to eq("water")
  end

  it "parses a leading unicode fraction" do
    result = parse("½ cup white sugar")

    expect(result.quantity).to eq(1/2r)
    expect(result.unit).to eq(:cup)
    expect(result.name).to eq("white sugar")
  end

  it "parses tablespoons and teaspoons" do
    expect(parse("2 tablespoons olive oil").unit).to eq(:tablespoon)
    expect(parse("¼ teaspoon salt").unit).to eq(:teaspoon)
    expect(parse("¼ teaspoon salt").quantity).to eq(1/4r)
  end

  it "parses ounces and pounds" do
    expect(parse("1 lb. potatoes").unit).to eq(:pound)
    expect(parse("8 ounces cream cheese").unit).to eq(:ounce)
  end

  it "uses the parenthetical can size as the amount" do
    result = parse("1 (14 ounce) can diced tomatoes")

    expect(result.quantity).to eq(14)
    expect(result.unit).to eq(:ounce)
    expect(result.name).to eq("diced tomatoes")
  end

  it "parses a count with no unit" do
    result = parse("1 onion, chopped")

    expect(result.quantity).to eq(1)
    expect(result.unit).to be_nil
    expect(result.name).to eq("onion, chopped")
  end

  it "returns the raw line when there is no quantity" do
    result = parse("salt to taste")

    expect(result.quantity).to be_nil
    expect(result.unit).to be_nil
    expect(result.name).to eq("salt to taste")
  end

  it "strips a leading of after the unit" do
    expect(parse("2 cups of bread flour").name).to eq("bread flour")
  end
end
