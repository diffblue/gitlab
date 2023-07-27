# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSubscriptions::UserAddOnAssignment, feature_category: :seat_cost_management do
  describe 'associations' do
    it { is_expected.to belong_to(:user).inverse_of(:assigned_add_ons) }
    it { is_expected.to belong_to(:add_on_purchase).inverse_of(:assigned_users) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:user) }
    it { is_expected.to validate_presence_of(:add_on_purchase) }

    context 'for uniqueness' do
      subject { build(:gitlab_subscription_user_add_on_assignment) }

      it { is_expected.to validate_uniqueness_of(:add_on_purchase_id).scoped_to(:user_id) }
    end
  end

  describe 'scopes' do
    describe '.by_user' do
      let(:user) { create(:user) }
      let(:user_assignment) { create(:gitlab_subscription_user_add_on_assignment, user: user) }
      let(:other_assignment) { create(:gitlab_subscription_user_add_on_assignment) }

      subject(:user_assignments) { described_class.by_user(user) }

      it 'returns assignments associated with user' do
        expect(user_assignments).to match_array([user_assignment])
      end
    end
  end
end
