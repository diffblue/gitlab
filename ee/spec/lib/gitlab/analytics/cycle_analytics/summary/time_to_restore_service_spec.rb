# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Analytics::CycleAnalytics::Summary::TimeToRestoreService, feature_category: :devops_reports do
  let(:stage) { build(:cycle_analytics_stage) }
  let(:user) { build(:user) }

  let(:options) do
    {
      from: 5.days.ago,
      to: 2.days.ago
    }
  end

  subject(:result) { described_class.new(stage: stage, current_user: user, options: options).value }

  context 'when the DORA service returns non-successful status' do
    it 'returns nil' do
      expect_next_instance_of(Dora::AggregateMetricsService) do |service|
        expect(service).to receive(:execute).and_return({ status: :error })
      end

      expect(result).to eq(nil)
    end
  end

  context 'when the DORA service returns 0 as value' do
    it 'returns "none" value' do
      expect_next_instance_of(Dora::AggregateMetricsService) do |service|
        expect(service).to receive(:execute).and_return({ status: :success,
data: [{ 'time_to_restore_service' => 0 }] })
      end

      expect(result.to_s).to eq('-')
    end
  end

  context 'when the DORA service returns the value' do
    it 'returns the value in days' do
      expect_next_instance_of(Dora::AggregateMetricsService) do |service|
        expect(service).to receive(:execute).and_return({ status: :success,
data: [{ 'time_to_restore_service' => 5.days.to_i }] })
      end

      expect(result.to_s).to eq('5.0')
    end
  end

  describe '#links' do
    subject { described_class.new(stage: stage, current_user: user, options: options).links }

    it 'displays documentation link and group dashboard link' do
      helpers = Gitlab::Routing.url_helpers

      expect(subject).to match_array(
        [
          {
            "name" => _('Time to Restore Service'),
            "url" => helpers.group_analytics_ci_cd_analytics_path(stage.parent, tab: 'time-to-restore-service'),
            "label" => s_('ValueStreamAnalytics|Dashboard')
          },
          {
            "name" => _('Time to Restore Service'),
            "url" => helpers.help_page_path('user/analytics/index', anchor: 'time-to-restore-service'),
            "docs_link" => true,
            "label" => s_('ValueStreamAnalytics|Go to docs')
          }
        ]
      )
    end

    context 'for a stage with project' do
      let_it_be(:group) { create(:group) }
      let_it_be(:project) { create(:project, group: group).reload }
      let(:stage) { build(:cycle_analytics_stage, project: project) }

      it 'displays documentation link and project dashboard link' do
        helpers = Gitlab::Routing.url_helpers

        expect(subject).to match_array(
          [
            {
              "name" => _('Time to Restore Service'),
              "url" => helpers.charts_project_pipelines_path(project, chart: 'time-to-restore-service'),
              "label" => s_('ValueStreamAnalytics|Dashboard')
            },
            {
              "name" => _('Time to Restore Service'),
              "url" => helpers.help_page_path('user/analytics/index', anchor: 'time-to-restore-service'),
              "docs_link" => true,
              "label" => s_('ValueStreamAnalytics|Go to docs')
            }
          ]
        )
      end
    end
  end
end
