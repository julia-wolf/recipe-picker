require "rails_helper"

RSpec.describe RecipeImporter do
  let(:dataset) { Rails.root.join("spec/fixtures/files/recipes_sample.json") }

  it "imports recipes, dedupes ingredients, and is idempotent" do
    described_class.import(dataset)
    described_class.import(dataset)

    expect(Recipe.count).to eq(2)
    expect(Ingredient.where(normalized_name: "all purpose flour").count).to eq(1)
    expect(RecipeIngredient.count).to eq(5)

    cornbread = Recipe.find_by!(title: "Golden Sweet Cornbread")
    expect(cornbread.prep_time).to eq(10)
    expect(cornbread.image_url).to eq("https://example.com/cornbread.jpg")
    expect(cornbread.recipe_ingredients.map(&:display_text)).to include("125 g all-purpose flour")
  end

  it "raises when the dataset is missing" do
    expect { described_class.import(Rails.root.join("missing.json")) }.to raise_error(ArgumentError, /Missing dataset/)
  end


  it "rejects a remote URL that is not the official dataset" do
    expect {
      described_class.import("http://169.254.169.254/latest/meta-data/")
    }.to raise_error(ArgumentError, /official dataset/)
  end

  it "imports a gzipped local file" do
    file = Tempfile.new([ "recipes", ".json.gz" ])
    Zlib::GzipWriter.open(file.path) { |gz| gz.write(File.read(dataset)) }

    described_class.import(file.path)
    file.close!

    expect(Recipe.count).to eq(2)
  end
end
