# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::Aggregations::Epics::LazyEpicAggregate do
  include_context 'includes EpicAggregate constants'

  let(:query_ctx) do
    {}
  end

  let(:epic_id) { 37 }
  let(:epic_iid) { 18 }
  let(:child_epic_id) { 38 }

  describe '#initialize' do
    it 'requires either :weight_sum, :health_status_sum or :count as a facet', :aggregate_failures do
      expect { described_class.new(query_ctx, epic_id, :nonsense) }.to raise_error(ArgumentError, /Invalid aggregate facet/)
      expect { described_class.new(query_ctx, epic_id, nil) }.to raise_error(ArgumentError, /No aggregate facet/)
      expect { described_class.new(query_ctx, epic_id, "") }.to raise_error(ArgumentError, /No aggregate facet/)
    end

    context 'with valid facets :weight_sum, :health_status_sum or :count' do
      specify 'as a symbol', :aggregate_failures do
        [WEIGHT_SUM, COUNT, HEALTH_STATUS_SUM].each do |valid_facet|
          expect { described_class.new(query_ctx, epic_id, valid_facet) }.not_to raise_error
        end
      end

      specify 'as a string', :aggregate_failures do
        %w(weight_sum health_status_sum count).each do |valid_facet|
          expect { described_class.new(query_ctx, epic_id, valid_facet) }.not_to raise_error
        end
      end
    end

    it 'adds the epic_id to lazy state' do
      described_class.new(query_ctx, epic_id, COUNT)

      expect(query_ctx[:lazy_epic_aggregate][:pending_ids]).to match [epic_id]
    end

    it 'adds facets to lazy state' do
      described_class.new(query_ctx, epic_id, COUNT)
      described_class.new(query_ctx, epic_id, WEIGHT_SUM)
      described_class.new(query_ctx, epic_id, HEALTH_STATUS_SUM)

      expect(query_ctx[:lazy_epic_aggregate][:facets]).to match_array [COUNT, WEIGHT_SUM, HEALTH_STATUS_SUM]
    end
  end

  describe '#epic_aggregate' do
    let(:single_record) do
      { iid: 6, issues_count: 4, issues_weight_sum: 9, parent_id: nil, issues_state_id: OPENED_ISSUE_STATE, epic_state_id: OPENED_EPIC_STATE, issues_at_risk: 1, issues_needing_attention: 2, issues_on_track: 3 }
    end

    let(:epic_info_node) { Gitlab::Graphql::Aggregations::Epics::EpicNode.new(epic_id, [single_record]) }

    subject { described_class.new(query_ctx, epic_id, HEALTH_STATUS_SUM) }

    before do
      subject.instance_variable_set(:@lazy_state, fake_state)
    end

    context 'if the record has already been loaded' do
      let(:fake_state) do
        { facets: Set.new, pending_ids: Set.new, tree: { epic_id => epic_info_node } }
      end

      it 'does not make the query again' do
        expect(epic_info_node).to receive(:aggregate_health_status_sum)
        expect(Gitlab::Graphql::Loaders::BulkEpicAggregateLoader).not_to receive(:new)

        subject.epic_aggregate
      end
    end

    context 'if the record has not been loaded' do
      let(:other_epic_id) { 39 }
      let(:fake_state) do
        { facets: Set.new, pending_ids: Set.new([epic_id, child_epic_id]), tree: {} }
      end

      let(:fake_data) do
        {
            epic_id => [{ epic_state_id: OPENED_EPIC_STATE, issues_count: 2, issues_weight_sum: 5, parent_id: nil, issues_state_id: OPENED_ISSUE_STATE, issues_at_risk: 1, issues_needs_attention: 2, issues_on_track: 3 }],
            child_epic_id => [{ epic_state_id: CLOSED_EPIC_STATE, issues_count: 4, issues_weight_sum: 17, parent_id: epic_id, issues_state_id: CLOSED_ISSUE_STATE, issues_at_risk: 1, issues_needs_attention: 2, issues_on_track: 3 }],
            other_epic_id => [{ epic_state_id: OPENED_EPIC_STATE, issues_count: 0, issues_weight_sum: 0, parent_id: nil, issues_state_id: nil, issues_at_risk: nil, issues_needs_attention: nil, issues_on_track: nil }] # represents an epic with no parent and no issues
        }
      end

      before do |example|
        unless example.metadata[:skip_aggregate_loader_mock]
          expect_next_instance_of(Gitlab::Graphql::Loaders::BulkEpicAggregateLoader) do |loader|
            expect(loader).to receive(:execute).and_return(fake_data)
          end
        end
      end

      it 'clears the pending IDs' do
        subject.epic_aggregate

        lazy_state = subject.instance_variable_get(:@lazy_state)

        expect(lazy_state[:pending_ids]).to be_empty
      end

      context 'when different facets are passed', :skip_aggregate_loader_mock do
        let(:requested_facets) { [] }
        let(:fake_state) do
          { facets: Set.new(requested_facets), pending_ids: Set.new([epic_id, child_epic_id]), tree: {} }
        end

        context 'when health_status_sum facet is requested' do
          let(:requested_facets) { [HEALTH_STATUS_SUM] }

          it 'forwards count_health_status true to aggregate loader' do
            expect_next_instance_of(Gitlab::Graphql::Loaders::BulkEpicAggregateLoader, epic_ids: anything, count_health_status: true) do |loader|
              allow(loader).to receive(:execute).and_return(fake_data)
            end

            subject.epic_aggregate
          end
        end

        context 'when count and weight sum facets are requested' do
          let(:requested_facets) { [COUNT, WEIGHT_SUM] }

          it 'forwards negative count_health_status to aggregate loader' do
            expect_next_instance_of(Gitlab::Graphql::Loaders::BulkEpicAggregateLoader, epic_ids: anything, count_health_status: false) do |loader|
              allow(loader).to receive(:execute).and_return(fake_data)
            end

            subject.epic_aggregate
          end
        end
      end

      context 'if a block is provided' do
        let(:result) { 123 }

        subject do
          described_class.new(query_ctx, epic_id, HEALTH_STATUS_SUM) do |object|
            result
          end
        end

        it 'calls the block' do
          expect(subject.epic_aggregate).to eq result
        end
      end

      it 'creates the parent-child associations', :aggregate_failures do
        subject.epic_aggregate

        expect(tree[child_epic_id].parent_id).to eq epic_id
        expect(tree[epic_id].children.map(&:epic_id)).to match_array([child_epic_id])
      end

      context 'for a parent-child relationship' do
        it 'assembles recursive sums for the parent', :aggregate_failures do
          subject.epic_aggregate

          expect(tree[epic_id]).to have_aggregate(ISSUE_TYPE, COUNT, OPENED_ISSUE_STATE, 2)
          expect(tree[epic_id]).to have_aggregate(ISSUE_TYPE, COUNT, CLOSED_ISSUE_STATE, 4)
          expect(tree[epic_id]).to have_aggregate(ISSUE_TYPE, WEIGHT_SUM, OPENED_ISSUE_STATE, 5)
          expect(tree[epic_id]).to have_aggregate(ISSUE_TYPE, WEIGHT_SUM, CLOSED_ISSUE_STATE, 17)
          expect(tree[epic_id]).to have_aggregate(ISSUE_TYPE, HEALTH_STATUS_SUM, OPENED_ISSUE_STATE, ON_TRACK_STATUS, 3)
          expect(tree[epic_id]).to have_aggregate(ISSUE_TYPE, HEALTH_STATUS_SUM, OPENED_ISSUE_STATE, NEEDS_ATTENTION_STATUS, 2)
          expect(tree[epic_id]).to have_aggregate(ISSUE_TYPE, HEALTH_STATUS_SUM, OPENED_ISSUE_STATE, AT_RISK_STATUS, 1)
          expect(tree[epic_id]).to have_aggregate(EPIC_TYPE, COUNT, CLOSED_EPIC_STATE, 1)
        end
      end

      context 'for a standalone epic with no issues' do
        it 'assembles recursive sums', :aggregate_failures do
          subject.epic_aggregate

          expect(tree[other_epic_id]).to have_aggregate(ISSUE_TYPE, COUNT, OPENED_ISSUE_STATE, 0)
          expect(tree[other_epic_id]).to have_aggregate(ISSUE_TYPE, COUNT, CLOSED_ISSUE_STATE, 0)
          expect(tree[other_epic_id]).to have_aggregate(ISSUE_TYPE, WEIGHT_SUM, OPENED_ISSUE_STATE, 0)
          expect(tree[other_epic_id]).to have_aggregate(ISSUE_TYPE, WEIGHT_SUM, CLOSED_ISSUE_STATE, 0)
          expect(tree[other_epic_id]).to have_aggregate(EPIC_TYPE, COUNT, CLOSED_EPIC_STATE, 0)
        end
      end

      context 'when checking cached counts' do
        let_it_be(:epic) { create(:epic) }

        let(:aggregate_count) { 0 }

        let(:fake_data) do
          {
            epic.id => [{ epic_state_id: OPENED_EPIC_STATE, issues_count: aggregate_count,
                          issues_weight_sum: 0, parent_id: nil, issues_state_id: OPENED_ISSUE_STATE }]
          }
        end

        subject { described_class.new(query_ctx, epic.id, COUNT, epic: epic) }

        shared_examples 'no logged mismatch' do
          it 'does not log an error if cached counts match' do
            expect(Gitlab::AppJsonLogger).not_to receive(:error)

            subject.epic_aggregate
          end
        end

        it_behaves_like 'no logged mismatch'

        context 'when cached count does not match aggregate count' do
          let(:aggregate_count) { 1 }

          it 'does log an error if cached counts do not match' do
            expect(Gitlab::AppJsonLogger).to receive(:error).with(
              message: 'epic cached count mismatch',
              aggregation: :count,
              epic_id: epic.id
            )

            subject.epic_aggregate
          end

          context 'when check_epic_cached_values is disabled' do
            before do
              stub_feature_flags(check_epic_cached_values: false)
            end

            it_behaves_like 'no logged mismatch'
          end

          context 'when epic is not set' do
            subject { described_class.new(query_ctx, epic.id, COUNT) }

            it_behaves_like 'no logged mismatch'
          end
        end
      end
    end
  end

  def tree
    lazy_state = subject.instance_variable_get(:@lazy_state)
    lazy_state[:tree]
  end
end
