require "rails_helper"

RSpec.describe RecipesHelper, type: :helper do
  describe "#recipe_photo_tag" do
    subject(:html) { helper.recipe_photo_tag(recipe) }

    context "when the recipe has no image" do
      let(:recipe) { build(:recipe, title: "Omelette", image_url: nil) }

      it "renders the placeholder without Stimulus" do
        expect(html).to include("recipe-placeholder.svg")
        expect(html).to include("alt=\"Omelette\"")
        expect(html).not_to include("data-controller")
      end
    end

    context "when the recipe has a dataset photo URL" do
      let(:recipe) { build(:recipe, title: "Omelette", image_url: "https://example.com/omelette.jpg") }

      it "wires a Stimulus fallback for a 404" do
        expect(html).to include("data-controller=\"recipe-photo\"")
        expect(html).to include("recipe-photo#fallback")
        expect(html).to include("recipe-placeholder.svg")
      end
    end
  end

  describe "#recipe_time_lines" do
    subject(:lines) { helper.recipe_time_lines(recipe) }

    context "when prep and cook are both zero" do
      let(:recipe) { build(:recipe, title: "Omelette", prep_time: 0, cook_time: 0) }

      it { is_expected.to eq([ I18n.t("recipes.time.unknown") ]) }
    end

    context "when both prep and cook are present" do
      let(:recipe) { build(:recipe, title: "Omelette", prep_time: 5, cook_time: 10) }

      it "lists ready-in, prep, and cook on separate lines" do
        expect(lines).to eq(
          [
            I18n.t("recipes.time.ready_in", count: 15),
            I18n.t("recipes.time.preparation", count: 5),
            I18n.t("recipes.time.cook", count: 10)
          ]
        )
      end
    end

    context "when prep and cook add up to 20" do
      let(:recipe) { build(:recipe, title: "Omelette", prep_time: 10, cook_time: 10) }

      it "lists ready-in, prep, and cook" do
        expect(lines).to eq(
          [
            I18n.t("recipes.time.ready_in", count: 20),
            I18n.t("recipes.time.preparation", count: 10),
            I18n.t("recipes.time.cook", count: 10)
          ]
        )
      end
    end

    context "when the value is 1" do
      let(:recipe) { build(:recipe, title: "Omelette", prep_time: 1, cook_time: 0) }

      it "uses the singular minute form" do
        expect(lines).to eq(
          [
            I18n.t("recipes.time.ready_in", count: 1),
            I18n.t("recipes.time.preparation", count: 1)
          ]
        )
      end
    end
  end
end
