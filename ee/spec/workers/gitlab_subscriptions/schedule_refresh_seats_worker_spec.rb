# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSubscriptions::ScheduleRefreshSeatsWorker, feature_category: :seat_cost_management do
  subject(:worker) { described_class.new }

  describe '#perform' do
    before do
      stub_ee_application_setting(check_namespace_plan: true)
    end

    include_examples 'an idempotent worker' do
      it 'schedules GitlabSubscriptions::RefreshSeatsWorker to be performed with capacity' do
        expect(GitlabSubscriptions::RefreshSeatsWorker).to receive(:perform_with_capacity).twice

        subject
      end
    end

    context 'when not on GitLab.com' do
      before do
        stub_ee_application_setting(check_namespace_plan: false)
      end

      it 'does not schedule a worker to perform with capacity' do
        expect(GitlabSubscriptions::RefreshSeatsWorker).not_to receive(:perform_with_capacity)

        worker.perform
      end
    end
  end
end
