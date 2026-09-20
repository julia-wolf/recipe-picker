require "rails_helper"

RSpec.describe UnitConverter do
  def display(raw)
    described_class.display_text(IngredientParser.parse(raw))
  end

  it "converts cups to millilitres when the name is not in the USDA table" do
    expect(display("1 cup chopped onion")).to eq("240 ml chopped onion")
    expect(display("1 cup peanut butter")).to eq("240 ml peanut butter")
  end

  it "keeps oils and other liquids in millilitres" do
    expect(display("2 tablespoons olive oil")).to eq("30 ml olive oil")
    expect(display("1 cup vegetable oil")).to eq("240 ml vegetable oil")
    expect(display("1 ½ cups water")).to eq("360 ml water")
    expect(display(".666 cup milk")).to eq("159,8 ml milk")
    expect(display("11 \u204416 cups water")).to eq("165 ml water")
    expect(display("1 teaspoon vanilla extract")).to eq("5 ml vanilla extract")
  end

  it "converts the most common dry catalog ingredients from USDA cup weights" do
    expect(display("1 cup all-purpose flour")).to eq("125 g all-purpose flour")
    expect(display("1 cup white sugar")).to eq("200 g white sugar")
    expect(display("1 cup packed brown sugar")).to eq("220 g packed brown sugar")
    expect(display("1 cup butter")).to eq("227 g butter")
    expect(display("1 tablespoon all-purpose flour")).to eq("7,8 g all-purpose flour")
    expect(display("1 cup minced garlic")).to eq("136 g minced garlic")
    expect(display("1 teaspoon garlic powder")).to eq("3,1 g garlic powder")
    expect(display("1 cup rolled oats")).to eq("81 g rolled oats")
  end

  it "converts spoons to millilitres when the name is not in the USDA table" do
    expect(display("2 tablespoons soy sauce")).to eq("30 ml soy sauce")
  end

  it "converts ounces and pounds to grams" do
    expect(display("8 ounces cream cheese")).to eq("224 g cream cheese")
    expect(display("1 lb. potatoes")).to eq("454 g potatoes")
  end

  it "converts a canned weight from the parenthetical size" do
    expect(display("1 (14 ounce) can diced tomatoes")).to eq("392 g diced tomatoes")
  end

  it "keeps counts as counts" do
    expect(display("1 onion, chopped")).to eq("1 onion, chopped")
    expect(display("2 eggs")).to eq("2 eggs")
  end

  it "falls back to the original line when nothing is convertible" do
    expect(display("salt to taste")).to eq("salt to taste")
  end
end
