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

  describe '.find_or_create_by_name' do
    subject(:find_or_create_by_name) { described_class.find_or_create_by_name(add_on_name) }

    let(:add_on_name) { :code_suggestions }

    context 'when a record was found' do
      let_it_be(:add_on) { create(:gitlab_subscription_add_on) }

      it 'returns the found add-on' do
        expect(find_or_create_by_name).to eq(add_on)
      end

      it 'does not create a new record' do
        expect { find_or_create_by_name }.not_to change { described_class.count }
      end
    end

    it 'creates a new record with the correct description' do
      add_on = find_or_create_by_name

      expect(add_on).to be_an_instance_of(described_class)
      expect(add_on).to have_attributes(
        name: add_on_name.to_s,
        description: described_class.descriptions[add_on_name]
      )
    end
  end
end
