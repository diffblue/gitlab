# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSubscriptions::AddOnPurchase, feature_category: :subscription_management do
  subject { build(:gitlab_subscription_add_on_purchase) }

  describe 'associations' do
    it { is_expected.to belong_to(:add_on).with_foreign_key(:subscription_add_on_id).inverse_of(:add_on_purchases) }
    it { is_expected.to belong_to(:namespace) }

    it do
      is_expected.to have_many(:assigned_users)
        .class_name('GitlabSubscriptions::UserAddOnAssignment').inverse_of(:add_on_purchase)
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:add_on) }
    it { is_expected.to validate_presence_of(:namespace) }
    it { is_expected.to validate_presence_of(:expires_on) }

    it { is_expected.to validate_uniqueness_of(:subscription_add_on_id).scoped_to(:namespace_id) }

    it { is_expected.to validate_presence_of(:quantity) }
    it { is_expected.to validate_numericality_of(:quantity).only_integer.is_greater_than_or_equal_to(1) }

    it { is_expected.to validate_presence_of(:purchase_xid) }
    it { is_expected.to validate_length_of(:purchase_xid).is_at_most(255) }
  end

  describe 'scopes' do
    let_it_be(:namespace) { create(:namespace) }
    let_it_be(:add_on) { create(:gitlab_subscription_add_on) }

    let_it_be(:add_on_purchase) { create(:gitlab_subscription_add_on_purchase, add_on: add_on, namespace: namespace) }

    describe '.active' do
      it 'returns only active add_on_purchases' do
        create(:gitlab_subscription_add_on_purchase, add_on: add_on, expires_on: 1.day.ago)

        expect(described_class.count).to eq(2)
        expect(described_class.active).to contain_exactly(add_on_purchase)
      end
    end

    describe '.by_add_on_name' do
      it 'returns records filtered by namespace' do
        expect(described_class.by_add_on_name('foo-bar')).to eq([])
        expect(described_class.by_add_on_name('code_suggestions')).to contain_exactly(add_on_purchase)
      end
    end
  end
end
