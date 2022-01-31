# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::CycleAnalytics::ConsistencyCheckService, :aggregate_failures do
  let_it_be_with_refind(:group) { create(:group) }
  let_it_be_with_refind(:subgroup) { create(:group, parent: group) }

  let_it_be(:project1) { create(:project, group: group) }
  let_it_be(:project2) { create(:project, group: subgroup) }

  subject(:service_response) { described_class.new(group: group, event_model: event_model).execute }

  shared_examples 'consistency check examples' do
    context 'when two records are deleted' do
      before do
        stub_licensed_features(cycle_analytics_for_groups: true)
        Analytics::CycleAnalytics::DataLoaderService.new(group: group, model: event_model.issuable_model).execute

        record1.delete
        record3.delete
      end

      it 'cleans up the stage event records' do
        expect(service_response).to be_success
        expect(service_response.payload[:reason]).to eq(:group_processed)

        all_stage_events = event_model.all
        expect(all_stage_events.size).to eq(1)
        expect(all_stage_events.first[event_model.issuable_id_column]).to eq(record2.id)
      end
    end

    describe 'validation' do
      context 'when license is missing' do
        before do
          stub_licensed_features(cycle_analytics_for_groups: false)
        end

        it 'fails' do
          expect(service_response).to be_error
          expect(service_response.payload[:reason]).to eq(:missing_license)
        end
      end

      context 'when sub-group is given' do
        let(:group) { subgroup }

        before do
          stub_licensed_features(cycle_analytics_for_groups: true)
        end

        it 'fails' do
          expect(service_response).to be_error
          expect(service_response.payload[:reason]).to eq(:requires_top_level_group)
        end
      end
    end
  end

  context 'for issue based stage' do
    let(:event_model) { Analytics::CycleAnalytics::IssueStageEvent }
    let!(:record1) { create(:issue, :closed, project: project1) }
    let!(:record2) { create(:issue, :closed, project: project2) }
    let!(:record3) { create(:issue, :closed, project: project2) }

    let!(:stage) { create(:cycle_analytics_group_stage, group: group, start_event_identifier: :issue_created, end_event_identifier: :issue_closed) }

    it_behaves_like 'consistency check examples'
  end

  context 'for merge request based stage' do
    let(:event_model) { Analytics::CycleAnalytics::MergeRequestStageEvent }
    let!(:record1) { create(:merge_request, :closed_last_month, project: project1) }
    let!(:record2) { create(:merge_request, :closed_last_month, project: project2) }
    let!(:record3) { create(:merge_request, :closed_last_month, project: project2) }

    let!(:stage) { create(:cycle_analytics_group_stage, group: group, start_event_identifier: :merge_request_created, end_event_identifier: :merge_request_closed) }

    it_behaves_like 'consistency check examples'
  end
end
