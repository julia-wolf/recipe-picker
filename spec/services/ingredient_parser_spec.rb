require "rails_helper"

RSpec.describe IngredientParser do
  describe ".parse" do
    subject(:result) { described_class.parse(raw) }

    context "when the line is a simple cup measure" do
      let(:raw) { "1 cup all-purpose flour" }

      it "extracts quantity, unit, name, and the original line" do
        expect(result).to have_attributes(
          quantity: 1,
          unit: :cup,
          name: "all-purpose flour",
          raw: "1 cup all-purpose flour"
        )
      end
    end

    context "when the quantity is a mixed unicode fraction" do
      let(:raw) { "1 ½ cups water" }

      it { is_expected.to have_attributes(quantity: 3/2r, unit: :cup, name: "water") }
    end

    context "when the quantity is an ascii mixed number" do
      let(:raw) { "1 1/2 cups water" }

      it { is_expected.to have_attributes(quantity: 3/2r, unit: :cup) }
    end

    context "when the quantity is a leading decimal without a zero" do
      let(:raw) { ".666 cup milk" }

      it { is_expected.to have_attributes(quantity: 0.666, unit: :cup, name: "milk") }
    end

    context "when the fraction uses a unicode fraction slash" do
      let(:raw) { "11 \u204416 cups water" }

      it { is_expected.to have_attributes(quantity: 11/16r, unit: :cup, name: "water") }
    end

    context "when the quantity is a leading unicode fraction" do
      let(:raw) { "½ cup white sugar" }

      it { is_expected.to have_attributes(quantity: 1/2r, unit: :cup, name: "white sugar") }
    end

    context "when the unit is a tablespoon" do
      let(:raw) { "2 tablespoons olive oil" }

      it { is_expected.to have_attributes(unit: :tablespoon) }
    end

    context "when the unit is a teaspoon" do
      let(:raw) { "¼ teaspoon salt" }

      it { is_expected.to have_attributes(unit: :teaspoon, quantity: 1/4r) }
    end

    context "when the unit is a pound" do
      let(:raw) { "1 lb. potatoes" }

      it { is_expected.to have_attributes(unit: :pound) }
    end

    context "when the unit is an ounce" do
      let(:raw) { "8 ounces cream cheese" }

      it { is_expected.to have_attributes(unit: :ounce) }
    end

    context "when the line has a parenthetical can size" do
      let(:raw) { "1 (14 ounce) can diced tomatoes" }

      it "uses the inner weight as the amount" do
        expect(result).to have_attributes(quantity: 14, unit: :ounce, name: "diced tomatoes")
      end
    end

    context "when the line is a count with no unit" do
      let(:raw) { "1 onion, chopped" }

      it { is_expected.to have_attributes(quantity: 1, unit: nil, name: "onion, chopped") }
    end

    context "when the name starts with of" do
      let(:raw) { "2 cups of bread flour" }

      it { is_expected.to have_attributes(name: "bread flour") }
    end

    context "when the line has no quantity" do
      let(:raw) { "salt to taste" }

      it "returns the raw line" do
        expect(result).to have_attributes(quantity: nil, unit: nil, name: "salt to taste")
      end
    end
  end
end
