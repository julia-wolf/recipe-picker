require "rails_helper"

RSpec.describe UnitConverter do
  describe ".display_text" do
    def display(raw)
      described_class.display_text(IngredientParser.parse(raw))
    end

    context "when converting cups to millilitres" do
      {
        "1 cup chopped onion" => "240 ml chopped onion",
        "1 cup peanut butter" => "240 ml peanut butter",
        "1 cup vegetable oil" => "240 ml vegetable oil",
        "1 ½ cups water" => "360 ml water",
        ".666 cup milk" => "159,8 ml milk",
        "11 \u204416 cups water" => "165 ml water",
        "1 cup unsweetened cocoa powder" => "240 ml unsweetened cocoa powder",
        "1 cup mayonnaise" => "240 ml mayonnaise"
      }.each do |raw, expected|
        it "converts #{raw.inspect} to #{expected.inspect}" do
          expect(display(raw)).to eq(expected)
        end
      end
    end

    context "when converting cups of dry ingredients to grams" do
      {
        "1 cup all-purpose flour" => "125 g all-purpose flour",
        "1 cup white sugar" => "200 g white sugar",
        "1 cup packed brown sugar" => "220 g packed brown sugar",
        "1 cup butter" => "227 g butter",
        "1 cup minced garlic" => "136 g minced garlic",
        "1 cup rolled oats" => "81 g rolled oats",
        "1 cup confectioners' sugar" => "120 g confectioners' sugar"
      }.each do |raw, expected|
        it "converts #{raw.inspect} to #{expected.inspect}" do
          expect(display(raw)).to eq(expected)
        end
      end
    end

    context "when the unit is a teaspoon or tablespoon" do
      {
        "2 tablespoons olive oil" => "2 tablespoons olive oil",
        "1 tablespoon all-purpose flour" => "1 tablespoon all-purpose flour",
        "1 teaspoon salt" => "1 teaspoon salt",
        "1 teaspoon vanilla extract" => "1 teaspoon vanilla extract",
        "2 tablespoons soy sauce" => "2 tablespoons soy sauce"
      }.each do |raw, expected|
        it "leaves #{raw.inspect} as written" do
          expect(display(raw)).to eq(expected)
        end
      end
    end

    context "when converting mass" do
      {
        "8 ounces cream cheese" => "224 g cream cheese",
        "1 lb. potatoes" => "454 g potatoes",
        "6.1 g salt" => "6 g salt",
        "1 (14 ounce) can diced tomatoes" => "392 g diced tomatoes"
      }.each do |raw, expected|
        it "converts #{raw.inspect} to #{expected.inspect}" do
          expect(display(raw)).to eq(expected)
        end
      end
    end

    context "when leaving a line as written" do
      {
        "1 onion, chopped" => "1 onion, chopped",
        "2 eggs" => "2 eggs",
        "1 bunch cilantro" => "1 bunch cilantro",
        "salt to taste" => "salt to taste"
      }.each do |raw, expected|
        it "leaves #{raw.inspect} as written" do
          expect(display(raw)).to eq(expected)
        end
      end
    end
  end
end
