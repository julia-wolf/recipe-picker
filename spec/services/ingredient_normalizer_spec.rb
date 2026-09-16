require "rails_helper"

RSpec.describe IngredientNormalizer do
  it "downcases and strips punctuation" do
    expect(described_class.call("all-purpose flour")).to eq("all purpose flour")
  end

  it "squeezes leftover spaces" do
    expect(described_class.call("  Extra-Virgin   Olive Oil  ")).to eq("extra virgin olive oil")
  end

  it "singularizes so egg and eggs share a key" do
    expect(described_class.call("eggs")).to eq("egg")
    expect(described_class.call("egg")).to eq("egg")
    expect(described_class.call("tomatoes")).to eq("tomato")
  end

  it "strips a leading pantry amount without changing stored recipe names" do
    expect(described_class.pantry("6 eggs")).to eq("egg")
    expect(described_class.pantry("6eggs")).to eq("egg")
    expect(described_class.call("6 eggs")).to eq("6 egg")
  end
end
