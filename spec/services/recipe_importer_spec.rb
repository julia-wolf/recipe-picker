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
    expect(cornbread.recipe_ingredients.map(&:display_text)).to include("240 ml cornmeal")
    expect(cornbread.recipe_ingredients.map(&:display_text)).to include("2 g salt")
  end

  it "raises when the dataset is missing" do
    expect { described_class.import(Rails.root.join("missing.json")) }.to raise_error(ArgumentError, /Missing dataset/)
  end

  it "keeps recipe ids aligned when inserting in small batches" do
    stub_const("#{described_class}::BATCH_SIZE", 1)

    described_class.import(dataset)

    expect(Recipe.find_by!(title: "Golden Sweet Cornbread").recipe_ingredients.count).to eq(3)
    expect(Recipe.find_by!(title: "Simple Salad").recipe_ingredients.count).to eq(2)
  end


  it "rejects a remote URL that is not DATASET_URL" do
    expect {
      described_class.import("http://169.254.169.254/latest/meta-data/")
    }.to raise_error(ArgumentError, /official dataset/)
  end

  it "requires DATASET_URL" do
    previous = ENV.delete("DATASET_URL")

    expect { described_class.dataset_url }.to raise_error(KeyError, /DATASET_URL/)
  ensure
    previous.nil? ? ENV.delete("DATASET_URL") : ENV["DATASET_URL"] = previous
  end

  it "unwraps Meredith image proxy urls and leaves plain urls alone" do
    file = Tempfile.new([ "recipes", ".json" ])
    file.write(
      [
        {
          "title" => "Omelette",
          "cook_time" => 5,
          "prep_time" => 5,
          "ingredients" => [ "1 egg" ],
          "image" => "https://imagesvc.meredithcorp.io/v3/mm/image?url=https%3A%2F%2Fimages.media-allrecipes.com%2Fuserphotos%2F970158.jpg"
        },
        {
          "title" => "Salad",
          "cook_time" => 0,
          "prep_time" => 5,
          "ingredients" => [ "1 tomato" ],
          "image" => "https://example.com/salad.jpg"
        }
      ].to_json
    )
    file.close

    described_class.import(file.path)

    expect(Recipe.find_by!(title: "Omelette").image_url).to eq(
      "https://images.media-allrecipes.com/userphotos/970158.jpg"
    )
    expect(Recipe.find_by!(title: "Salad").image_url).to eq("https://example.com/salad.jpg")
  ensure
    file.close!
  end

  it "imports a gzipped local file" do
    file = Tempfile.new([ "recipes", ".json.gz" ])
    Zlib::GzipWriter.open(file.path) { |gz| gz.write(File.read(dataset)) }

    described_class.import(file.path)
    file.close!

    expect(Recipe.count).to eq(2)
  end
end
