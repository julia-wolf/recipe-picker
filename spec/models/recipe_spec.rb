require "rails_helper"

RSpec.describe Recipe, type: :model do
  describe "#total_time" do
    subject(:total_time) { recipe.total_time }

    let(:recipe) { described_class.new(title: "Omelette", prep_time:, cook_time:) }

    context "when prep and cook are zero" do
      let(:prep_time) { 0 }
      let(:cook_time) { 0 }

      it { is_expected.to be_nil }
    end

    context "when prep and cook are present" do
      let(:prep_time) { 5 }
      let(:cook_time) { 10 }

      it { is_expected.to eq(15) }
    end
  end
end
