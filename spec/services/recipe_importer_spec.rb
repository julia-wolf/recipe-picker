require "rails_helper"

RSpec.describe RecipeImporter do
  let(:dataset) { file_fixture("recipes_sample.json") }

  describe ".import" do
    context "when importing a local file" do
      it "creates recipes and converted ingredient rows" do
        expect { described_class.import(dataset) }
          .to change(Recipe, :count).from(0).to(2)
          .and change(RecipeIngredient, :count).from(0).to(5)

        cornbread = Recipe.find_by!(title: "Golden Sweet Cornbread")
        expect(cornbread).to have_attributes(
          prep_time: 10,
          image_url: "https://example.com/cornbread.jpg"
        )
        expect(cornbread.recipe_ingredients.map(&:display_text)).to include(
          "125 g all-purpose flour",
          "240 ml cornmeal",
          "1/4 teaspoon salt"
        )
      end

      it "reuses one ingredient row for the same normalized name" do
        described_class.import(dataset)

        expect(Ingredient.where(normalized_name: "all purpose flour").count).to eq(1)
      end

      it "is idempotent" do
        described_class.import(dataset)

        expect { described_class.import(dataset) }
          .not_to change { [ Recipe.count, Ingredient.count, RecipeIngredient.count ] }
      end

      it "raises when the dataset is missing" do
        expect { described_class.import(Rails.root.join("missing.json")) }
          .to raise_error(ArgumentError, /Missing dataset/)
      end

      it "keeps recipe ids aligned when inserting in small batches" do
        stub_const("#{described_class}::BATCH_SIZE", 1)

        described_class.import(dataset)

        expect(Recipe.find_by!(title: "Golden Sweet Cornbread").recipe_ingredients.count).to eq(3)
        expect(Recipe.find_by!(title: "Simple Salad").recipe_ingredients.count).to eq(2)
      end

      it "unwraps Meredith image proxy urls and leaves plain urls alone" do
        Tempfile.create([ "recipes", ".json" ]) do |file|
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
          file.flush

          described_class.import(file.path)

          expect(Recipe.find_by!(title: "Omelette").image_url).to eq(
            "https://images.media-allrecipes.com/userphotos/970158.jpg"
          )
          expect(Recipe.find_by!(title: "Salad").image_url).to eq("https://example.com/salad.jpg")
        end
      end

      it "imports a gzipped local file" do
        Tempfile.create([ "recipes", ".json.gz" ]) do |file|
          Zlib::GzipWriter.open(file.path) { |gz| gz.write(dataset.read) }

          described_class.import(file.path)

          expect(Recipe.count).to eq(2)
        end
      end
    end

    it "rejects a remote URL that is not DATASET_URL" do
      expect {
        described_class.import("http://169.254.169.254/latest/meta-data/")
      }.to raise_error(ArgumentError, /official dataset/)
    end
  end

  describe ".dataset_url" do
    context "when DATASET_URL is unset" do
      around do |example|
        previous = ENV.delete("DATASET_URL")
        example.run
      ensure
        previous.nil? ? ENV.delete("DATASET_URL") : ENV["DATASET_URL"] = previous
      end

      it "raises KeyError" do
        expect { described_class.dataset_url }.to raise_error(KeyError, /DATASET_URL/)
      end
    end
  end
end
