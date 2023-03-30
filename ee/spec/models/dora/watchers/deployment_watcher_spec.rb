# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dora::Watchers::DeploymentWatcher, feature_category: :devops_reports do
  describe ".mount" do
    context 'when deployment succeeded' do
      let(:deployment) { create(:deployment, :running) }

      it 'calls for processing successful event' do
        expect(Dora::Watchers).to receive(:process_event).with(deployment, :successful)

        deployment.succeed!
      end
    end
  end

  describe '#process' do
    subject { described_class.new(deployment, event) }

    let(:deployment) { create(:deployment, :success, finished_at: finished_at) }
    let(:finished_at) { 1.day.ago }
    let(:event) { :successful }

    it 'schedules metric refresh for finished_at date' do
      expect(::Dora::DailyMetrics::RefreshWorker)
        .to receive(:perform_in).with(
          5.minutes,
          deployment.environment_id,
          finished_at.to_date.to_s)

      subject.process
    end
  end
end
