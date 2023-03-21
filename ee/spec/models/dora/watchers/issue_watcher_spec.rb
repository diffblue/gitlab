# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dora::Watchers::IssueWatcher, feature_category: :devops_reports do
  describe ".mount" do
    context 'on issue close' do
      let!(:issue) { create(:issue) }

      it 'calls for processing closed event' do
        expect(Dora::Watchers).to receive(:process_event).with(issue, :closed)

        issue.close!
      end
    end

    context 'on issue reopen' do
      let!(:issue) { create(:issue, :closed) }

      it 'calls for processing reopen event' do
        expect(Dora::Watchers).to receive(:process_event).with(issue, :reopened)

        issue.reopen!
      end
    end

    context 'on issue create' do
      it 'calls for processing created event' do
        expect(Dora::Watchers).to receive(:process_event).with(kind_of(Issue), :created)

        create(:issue)
      end
    end
  end

  describe '#process' do
    subject { described_class.new(issue, event) }

    let(:event) { :closed }

    let_it_be(:production_env) { create(:environment, :production) }

    context 'when the issue is not an incident' do
      let(:issue) { create :issue, project: production_env.project }

      it 'does not schedule refresh worker' do
        expect(::Dora::DailyMetrics::RefreshWorker).not_to receive(:perform_async)

        subject.process
      end
    end

    context 'when there is not production environment' do
      let(:issue) { create :incident }

      it 'does not schedule refresh worker' do
        expect(::Dora::DailyMetrics::RefreshWorker).not_to receive(:perform_async)

        subject.process
      end
    end

    context 'when event is :closed' do
      let!(:issue) { create :incident, :closed, closed_at: closed_at, project: production_env.project }
      let(:closed_at) { 1.day.ago }

      it 'schedules metric refresh for closed_at date' do
        expect(::Dora::DailyMetrics::RefreshWorker)
          .to receive(:perform_async).with(production_env.id, closed_at.to_date.to_s)

        subject.process
      end
    end

    context 'when event is :reopened' do
      let!(:issue) { create :incident, :closed, closed_at: closed_at, project: production_env.project }
      let(:closed_at) { 1.day.ago }
      let(:event) { :reopened }

      it 'schedules metric refresh for closed_at date' do
        issue.closed_at = nil

        expect(::Dora::DailyMetrics::RefreshWorker)
          .to receive(:perform_async).with(production_env.id, closed_at.to_date.to_s)

        subject.process
      end
    end

    context 'when event is :created' do
      let!(:issue) { create :incident, created_at: created_at, project: production_env.project }
      let(:created_at) { 1.day.ago }
      let(:event) { :created }

      it 'schedules metric refresh for created_at date' do
        expect(::Dora::DailyMetrics::RefreshWorker)
          .to receive(:perform_async).with(production_env.id, created_at.to_date.to_s)

        subject.process
      end
    end
  end
end
