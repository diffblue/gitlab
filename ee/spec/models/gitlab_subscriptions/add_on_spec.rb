# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSubscriptions::AddOn, feature_category: :subscription_management do
  subject { build(:gitlab_subscription_add_on) }

  describe 'associations' do
    it { is_expected.to have_many(:add_on_purchases).with_foreign_key(:subscription_add_on_id).inverse_of(:add_on) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).ignoring_case_sensitivity }

    it { is_expected.to validate_presence_of(:description) }
    it { is_expected.to validate_length_of(:description).is_at_most(512) }
  end

  describe '.descriptions' do
    subject(:descriptions) { described_class.descriptions }

    it 'returns a description for each defined add-on' do
      expect(descriptions.stringify_keys.keys).to eq(described_class.names.keys)
      expect(descriptions.values.all?(&:present?)).to eq(true)
    end
  end
end
