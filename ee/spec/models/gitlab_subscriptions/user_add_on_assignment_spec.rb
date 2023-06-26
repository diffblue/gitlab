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
end
