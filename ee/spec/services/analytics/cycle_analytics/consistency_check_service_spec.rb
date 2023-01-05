# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::CycleAnalytics::ConsistencyCheckService, :aggregate_failures do
  let_it_be_with_refind(:group) { create(:group) }
  let_it_be_with_refind(:subgroup) { create(:group, parent: group) }

  let_it_be(:project1) { create(:project, group: group) }
  let_it_be(:project2) { create(:project, group: subgroup) }

  let(:service) { described_class.new(group: group, event_model: event_model) }

  subject(:service_response) { service.execute }

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

      context 'when running out of allotted time' do
        let(:runtime_limiter) { instance_double('Analytics::CycleAnalytics::RuntimeLimiter') }

        subject(:service_response) { service.execute(runtime_limiter: runtime_limiter) }

        before do
          stub_const("#{described_class.name}::BATCH_LIMIT", 1)
          allow(runtime_limiter).to receive(:over_time?).and_return(false, true)
        end

        it 'stops early, returns a cursor, and restarts next run from the given cursor' do
          model_name = event_model.issuable_model.name.underscore.pluralize
          initial_events = event_model.order_by_end_event(:asc).to_a

          cursor_data = {
            "#{model_name}_stage_event_hash_id": nil,
            "#{model_name}_cursor": {}
          }

          3.times do |i|
            allow(runtime_limiter).to receive(:over_time?).and_return(false, true)
            response = service.execute(runtime_limiter: runtime_limiter, cursor_data: cursor_data)

            last_processed_event = initial_events[i]

            expect(response.payload[:cursor]).to eq({
              'start_event_timestamp' => last_processed_event.start_event_timestamp.to_s(:inspect),
              'end_event_timestamp' => last_processed_event.end_event_timestamp.to_s(:inspect),
              event_model.issuable_id_column.to_s => last_processed_event[event_model.issuable_id_column].to_s
            })

            cursor_data = {
              "#{model_name}_stage_event_hash_id": response.payload[:stage_event_hash_id],
              "#{model_name}_cursor": response.payload[:cursor]
            }
          end

          all_stage_events = event_model.all
          expect(all_stage_events.size).to eq(1)
          expect(all_stage_events.first[event_model.issuable_id_column]).to eq(record2.id)
        end
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
    let!(:record1) { create(:issue, :closed, project: project1, created_at: 2.months.ago) }
    let!(:record2) { create(:issue, :closed, project: project2, created_at: 1.month.ago) }
    let!(:record3) { create(:issue, :closed, project: project2, created_at: 1.month.ago) }

    let!(:stage) { create(:cycle_analytics_stage, namespace: group, start_event_identifier: :issue_created, end_event_identifier: :issue_closed) }

    it_behaves_like 'consistency check examples'
  end

  context 'for merge request based stage' do
    let(:event_model) { Analytics::CycleAnalytics::MergeRequestStageEvent }
    let!(:record1) { create(:merge_request, :closed_last_month, project: project1, created_at: 3.months.ago) }
    let!(:record2) { create(:merge_request, :closed_last_month, project: project2, created_at: 2.months.ago) }
    let!(:record3) { create(:merge_request, :closed_last_month, project: project2, created_at: 2.months.ago) }

    let!(:stage) { create(:cycle_analytics_stage, namespace: group, start_event_identifier: :merge_request_created, end_event_identifier: :merge_request_closed) }

    it_behaves_like 'consistency check examples'
  end
end
