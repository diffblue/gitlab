# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSubscriptions::AddOnPurchase, feature_category: :saas_provisioning do
  subject { build(:gitlab_subscription_add_on_purchase) }

  describe 'associations' do
    it { is_expected.to belong_to(:add_on).with_foreign_key(:subscription_add_on_id).inverse_of(:add_on_purchases) }
    it { is_expected.to belong_to(:namespace).optional(true) }

    it do
      is_expected.to have_many(:assigned_users)
        .class_name('GitlabSubscriptions::UserAddOnAssignment').inverse_of(:add_on_purchase)
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:add_on) }
    it { is_expected.to validate_presence_of(:expires_on) }

    context 'when validating namespace presence' do
      context 'when on .com', :saas do
        before do
          stub_ee_application_setting(should_check_namespace_plan: true)
        end

        it { is_expected.to validate_presence_of(:namespace) }
      end

      context 'when not on .com' do
        it { is_expected.not_to validate_presence_of(:namespace) }
      end
    end

    it { is_expected.to validate_uniqueness_of(:subscription_add_on_id).scoped_to(:namespace_id) }
    it { is_expected.to validate_presence_of(:quantity) }
    it { is_expected.to validate_numericality_of(:quantity).only_integer.is_greater_than_or_equal_to(1) }

    it { is_expected.to validate_presence_of(:purchase_xid) }
    it { is_expected.to validate_length_of(:purchase_xid).is_at_most(255) }
  end

  describe 'scopes' do
    shared_context 'with add-on purchases' do
      let_it_be(:code_suggestions_add_on) { create(:gitlab_subscription_add_on) }

      let_it_be(:code_suggestion_expired_purchase) do
        create(:gitlab_subscription_add_on_purchase, expires_on: 1.day.ago, add_on: code_suggestions_add_on)
      end

      let_it_be(:code_suggestion_active_purchase) do
        create(:gitlab_subscription_add_on_purchase, add_on: code_suggestions_add_on)
      end

      let_it_be(:code_suggestion_active_purchase_for_project) do
        create(:gitlab_subscription_add_on_purchase, add_on: code_suggestions_add_on)
      end

      let_it_be(:project) do
        create(:project, group: code_suggestion_active_purchase_for_project.namespace)
      end
    end

    describe '.active' do
      include_context 'with add-on purchases'

      subject(:active_purchases) { described_class.active }

      it 'returns all the purchases that are not expired' do
        expect(active_purchases).to match_array(
          [code_suggestion_active_purchase, code_suggestion_active_purchase_for_project]
        )
      end
    end

    describe '.by_add_on_name' do
      include_context 'with add-on purchases'

      it 'returns records filtered by namespace' do
        expect(described_class.by_add_on_name('foo-bar')).to eq([])
        expect(described_class.by_add_on_name('code_suggestions')).to match_array(
          [code_suggestion_active_purchase, code_suggestion_active_purchase_for_project,
            code_suggestion_expired_purchase]
        )
      end
    end

    describe '.for_code_suggestions' do
      subject(:code_suggestion_purchases) { described_class.for_code_suggestions }

      include_context 'with add-on purchases'

      it 'returns all the purchases related to code_suggestions' do
        expect(code_suggestion_purchases).to match_array(
          [code_suggestion_active_purchase, code_suggestion_active_purchase_for_project,
            code_suggestion_expired_purchase]
        )
      end
    end

    describe '.for_project' do
      subject(:project_purchases) { described_class.for_project(project.id) }

      include_context 'with add-on purchases'

      it 'returns all the purchases related to a project' do
        expect(project_purchases).to match_array(
          [code_suggestion_active_purchase_for_project]
        )
      end
    end
  end

  describe '#already_assigned?' do
    let_it_be(:add_on_purchase) { create(:gitlab_subscription_add_on_purchase) }

    let(:user) { create(:user) }

    subject { add_on_purchase.already_assigned?(user) }

    context 'when the user has been already assigned' do
      before do
        create(:gitlab_subscription_user_add_on_assignment, add_on_purchase: add_on_purchase, user: user)
      end

      it { is_expected.to eq(true) }
    end

    context 'when user is not already assigned' do
      it { is_expected.to eq(false) }
    end
  end

  describe '#active?' do
    let_it_be(:add_on_purchase) { create(:gitlab_subscription_add_on_purchase) }

    subject { add_on_purchase.active? }

    it { is_expected.to eq(true) }

    context 'when subscription has expired' do
      it { travel_to(add_on_purchase.expires_on + 1.day) { is_expected.to eq(false) } }
    end
  end
end
