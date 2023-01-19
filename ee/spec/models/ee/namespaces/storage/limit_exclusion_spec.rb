# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::Storage::LimitExclusion, feature_category: :subscription_cost_management, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:namespace).required }
  end

  describe 'check constraints' do
    it 'enforces the reason and namespace NOT NULL constraint' do
      expect do
        ApplicationRecord.connection
        .execute('INSERT INTO namespaces_storage_limit_exclusions (reason, namespace_id) VALUES (NULL, NULL)')
      end.to raise_error(ActiveRecord::NotNullViolation)
    end
  end

  describe 'validations' do
    it { is_expected.to belong_to(:namespace).optional(false) }
    it { is_expected.to validate_presence_of(:reason) }
    it { is_expected.to validate_length_of(:reason).is_at_most(255) }
  end

  describe 'dependent destroy' do
    let(:namespace) { create(:namespace) }
    let!(:excluded_namespace) { create(:storage_limit_excluded_namespace, namespace: namespace) }

    it 'destroys the excluded namespace when the namespace is destroyed' do
      expect { namespace.destroy! }.to change { described_class.count }.by(-1)
    end
  end
end
