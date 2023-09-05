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
      let(:add_on_purchase) { create(:gitlab_subscription_add_on_purchase) }
      let!(:other_assignment) { create(:gitlab_subscription_user_add_on_assignment, add_on_purchase: add_on_purchase) }
      let!(:user_assignment) do
        create(:gitlab_subscription_user_add_on_assignment, add_on_purchase: add_on_purchase, user: user)
      end

      subject(:user_assignments) { described_class.by_user(user) }

      it 'returns assignments associated with user' do
        expect(described_class.count).to eq(2)

        expect(user_assignments).to match_array([user_assignment])
      end
    end

    describe '.for_user_ids' do
      context 'when supplied an empty array' do
        it 'returns no assignments' do
          create(:gitlab_subscription_user_add_on_assignment)

          expect(described_class.for_user_ids([])).to be_empty
        end
      end

      context 'when supplied user IDs that do not exist' do
        it 'returns no assignments' do
          create(:gitlab_subscription_user_add_on_assignment)

          expect(described_class.for_user_ids(non_existing_record_id)).to be_empty
        end
      end

      context 'when supplied user IDs for assigned users' do
        it 'returns the assignments for those users' do
          add_on_purchase = create(:gitlab_subscription_add_on_purchase)

          matching_assignment = create(:gitlab_subscription_user_add_on_assignment, add_on_purchase: add_on_purchase)
          create(:gitlab_subscription_user_add_on_assignment, add_on_purchase: add_on_purchase)

          expect(described_class.for_user_ids([matching_assignment.user_id])).to match_array [matching_assignment]
        end
      end

      context 'when supplied user IDs without assignments' do
        it 'returns no assignments' do
          create(:gitlab_subscription_user_add_on_assignment)
          unassigned_user = create(:user)

          expect(described_class.for_user_ids([unassigned_user.id])).to be_empty
        end
      end
    end

    describe '.for_active_add_on_purchase_ids' do
      context 'when supplied no add on purchase IDs' do
        it 'returns an empty collection' do
          create(:gitlab_subscription_user_add_on_assignment)

          expect(described_class.for_active_add_on_purchase_ids([])).to be_empty
        end
      end

      context 'when the supplied add on purchase IDs have no assignments' do
        it 'returns an empty collection' do
          add_on_purchase = create(:gitlab_subscription_add_on_purchase)

          expect(described_class.for_active_add_on_purchase_ids([add_on_purchase.id])).to be_empty
        end
      end

      context 'when the supplied add on purchase IDs do not exist' do
        it 'returns an empty collection' do
          expect(described_class.for_active_add_on_purchase_ids([non_existing_record_id])).to be_empty
        end
      end

      context 'when the supplied add on purchase IDs are for inactive purchases' do
        it 'returns an empty collection' do
          add_on_purchase = create(:gitlab_subscription_add_on_purchase, expires_on: 1.week.ago)
          create(:gitlab_subscription_user_add_on_assignment, add_on_purchase: add_on_purchase)

          expect(described_class.for_active_add_on_purchase_ids([add_on_purchase.id])).to be_empty
        end
      end

      context 'when the supplied add on purchase IDs are for active purchases' do
        it 'returns those assignments' do
          add_on_purchase = create(:gitlab_subscription_add_on_purchase)
          assignment = create(:gitlab_subscription_user_add_on_assignment, add_on_purchase: add_on_purchase)

          expect(described_class.for_active_add_on_purchase_ids([add_on_purchase.id]))
            .to match_array [assignment]
        end
      end
    end
  end
end
