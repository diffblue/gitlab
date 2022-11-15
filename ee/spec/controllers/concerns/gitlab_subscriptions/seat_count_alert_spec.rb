# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSubscriptions::SeatCountAlert, feature_category: :subscription_management do
  controller(ActionController::Base) do
    include GitlabSubscriptions::SeatCountAlert
  end

  let_it_be(:user) { create(:user) }
  let_it_be(:root_ancestor) { create(:group) }

  describe '#generate_seat_count_alert_data' do
    let(:response_data) do
      { namespace: root_ancestor, remaining_seat_count: 5, seats_in_use: 5, total_seat_count: 10 }
    end

    context 'when the user is not authenticated' do
      it 'does not set the seat count data' do
        expect(controller.generate_seat_count_alert_data(root_ancestor)).to be_nil
      end
    end

    context 'when the user is authenticated' do
      before do
        sign_in(user)
      end

      context 'when the namespace is nil' do
        it 'does not set the seat count data' do
          expect(controller.generate_seat_count_alert_data(nil)).to be_nil
        end
      end

      context 'when supplied a project' do
        it 'sets the data based on the root ancestor' do
          project = build(:project, namespace: root_ancestor)

          expect_next_instance_of(
            GitlabSubscriptions::Reconciliations::CalculateSeatCountDataService,
            namespace: root_ancestor,
            user: user
          ) do |service|
            expect(service).to receive(:execute).and_return(response_data)
          end

          expect(controller.generate_seat_count_alert_data(project)).to eq response_data
        end
      end

      context 'when supplied a top level group' do
        it 'sets the data based on that group' do
          expect_next_instance_of(
            GitlabSubscriptions::Reconciliations::CalculateSeatCountDataService,
            namespace: root_ancestor,
            user: user
          ) do |service|
            expect(service).to receive(:execute).and_return(response_data)
          end

          expect(controller.generate_seat_count_alert_data(root_ancestor)).to eq response_data
        end
      end

      context 'when supplied a subgroup' do
        it 'sets the data based on the root ancestor' do
          subgroup = build(:group, parent: root_ancestor)

          expect_next_instance_of(
            GitlabSubscriptions::Reconciliations::CalculateSeatCountDataService,
            namespace: root_ancestor,
            user: user
          ) do |service|
            expect(service).to receive(:execute).and_return(response_data)
          end

          expect(controller.generate_seat_count_alert_data(subgroup)).to eq response_data
        end
      end
    end
  end
end
