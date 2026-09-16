require "rails_helper"

RSpec.describe IngredientNormalizer do
  describe ".normalize" do
    it "downcases and strips punctuation" do
      expect(described_class.normalize("all-purpose flour")).to eq("all purpose flour")
    end

    it "squeezes leftover spaces" do
      expect(described_class.normalize("  Extra-Virgin   Olive Oil  ")).to eq("extra virgin olive oil")
    end

    it "singularizes so egg and eggs share a key" do
      expect(described_class.normalize("eggs")).to eq("egg")
      expect(described_class.normalize("egg")).to eq("egg")
      expect(described_class.normalize("tomatoes")).to eq("tomato")
    end

    it "does not strip a leading amount from a catalog name" do
      expect(described_class.normalize("6 eggs")).to eq("6 egg")
    end
  end

  describe ".without_amount" do
    it "strips a leading pantry amount" do
      expect(described_class.without_amount("6 eggs")).to eq("egg")
      expect(described_class.without_amount("6eggs")).to eq("egg")
    end
  end
end
