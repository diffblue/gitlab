# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSubscriptions::UserAddOnAssignments::CreateService, feature_category: :seat_cost_management do
  let_it_be(:namespace) { create(:group) }
  let_it_be(:add_on) { create(:gitlab_subscription_add_on) }
  let_it_be(:add_on_purchase) { create(:gitlab_subscription_add_on_purchase, namespace: namespace, add_on: add_on) }
  let_it_be(:user) { create(:user) }

  subject(:response) do
    described_class.new(add_on_purchase: add_on_purchase, user: user).execute
  end

  before_all do
    namespace.add_developer(user)
  end

  describe '#execute' do
    shared_examples 'success response' do
      it 'creates new records' do
        expect { subject }.to change { add_on_purchase.assigned_users.where(user: user).count }.by(1)
        expect(response).to be_success
      end
    end

    shared_examples 'error response' do |error_message|
      it 'does not create new records' do
        expect { subject }.not_to change { add_on_purchase.assigned_users.count }
        expect(response.errors).to include(error_message)
      end
    end

    it_behaves_like 'success response'

    context 'when user is already assigned' do
      before do
        create(:gitlab_subscription_user_add_on_assignment, add_on_purchase: add_on_purchase, user: user)
      end

      it 'does not create new record' do
        expect { subject }.not_to change { add_on_purchase.assigned_users.count }
        expect(response).to be_success
      end
    end

    context 'when seats are not available' do
      before do
        create(:gitlab_subscription_user_add_on_assignment, add_on_purchase: add_on_purchase, user: create(:user))
      end

      it_behaves_like 'error response', 'NO_SEATS_AVAILABLE'
    end

    context 'when user is not member of namespace' do
      let(:user) { create(:user) }

      it_behaves_like 'error response', 'INVALID_USER_MEMBERSHIP'
    end

    context 'when user has guest role' do
      let(:user) { namespace.add_guest(create(:user)).user }

      it_behaves_like 'error response', 'INVALID_USER_MEMBERSHIP'
    end

    context 'when user is member of subgroup' do
      let(:subgroup) { create(:group, parent: namespace) }
      let(:user) { subgroup.add_developer(create(:user)).user }

      it_behaves_like 'success response'
    end

    context 'when user is member of project' do
      let_it_be(:project) { create(:project, namespace: namespace) }
      let(:user) { project.add_developer(create(:user)).user }

      it_behaves_like 'success response'
    end

    context 'when user is member of shared group' do
      let(:invited_group) { create(:group) }
      let(:user) { invited_group.add_developer(create(:user)).user }

      before do
        create(:group_group_link, { shared_with_group: invited_group, shared_group: namespace })
      end

      it_behaves_like 'success response'
    end

    context 'when user is member of shared project' do
      let(:invited_group) { create(:group) }
      let_it_be(:project) { create(:project, namespace: namespace) }
      let(:user) { invited_group.add_developer(create(:user)).user }

      before do
        create(:project_group_link, project: project, group: invited_group)
      end

      it_behaves_like 'success response'
    end

    context 'with resource locking' do
      before do
        add_on_purchase.update!(quantity: 1)
      end

      it 'prevents from double booking assignment' do
        users = create_list(:user, 3)

        expect(add_on_purchase.assigned_users.count).to eq(0)

        users.map do |user|
          namespace.add_developer(user)

          Thread.new do
            described_class.new(
              add_on_purchase: add_on_purchase,
              user: user
            ).execute
          end
        end.each(&:join)

        expect(add_on_purchase.assigned_users.count).to eq(1)
      end

      context 'when NoSeatsAvailableError is raised' do
        let(:service_instance) { described_class.new(add_on_purchase: add_on_purchase, user: user) }

        subject(:response) { service_instance.execute }

        it 'handes the error correctly' do
          # fill up the available seats
          create(:gitlab_subscription_user_add_on_assignment, add_on_purchase: add_on_purchase)

          # Mock first call to return true to pass the validate phase
          expect(service_instance).to receive(:seats_available?).and_return(true)
          expect(service_instance).to receive(:seats_available?).and_call_original

          expect { subject }.not_to raise_error
          expect(response.errors).to include('NO_SEATS_AVAILABLE')
        end
      end
    end
  end
end
