# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::Aggregations::Issues::LazyBlockAggregate do
  let(:query_ctx) do
    {}
  end

  let(:issue_id) { 37 }
  let(:blocks_issue_id) { 18 }
  let(:blocking_issue_id) { 38 }

  describe '#initialize' do
    it 'adds the issue_id to the lazy state' do
      subject = described_class.new(query_ctx, issue_id)

      expect(subject.lazy_state[:pending_ids]).to match [issue_id]
      expect(subject.issue_id).to match issue_id
    end
  end

  describe '#block_aggregate' do
    subject { described_class.new(query_ctx, issue_id) }

    # We cannot directly stub IssueLink, otherwise we get a strange RSpec error
    let(:issue_link) { class_double('IssueLink').as_stubbed_const }
    let(:fake_state) do
      { pending_ids: Set.new, loaded_objects: {} }
    end

    before do
      subject.instance_variable_set(:@lazy_state, fake_state)
    end

    context 'when there is a block provided' do
      subject do
        described_class.new(query_ctx, issue_id) do |result|
          result.do_thing
        end
      end

      it 'calls the block' do
        expect(fake_state[:loaded_objects][issue_id]).to receive(:do_thing)

        subject.block_aggregate
      end
    end

    context 'if the record has already been loaded' do
      let(:fake_state) do
        { pending_ids: Set.new, loaded_objects: { issue_id => double(count: 10) } }
      end

      it 'does not make the query again' do
        expect(issue_link).not_to receive(:blocked_issuables_for_collection)

        subject.block_aggregate
      end
    end

    context 'if the record has not been loaded' do
      let(:other_issue_id) { 39 }
      let(:fake_state) do
        { pending_ids: Set.new([issue_id]), loaded_objects: {} }
      end

      let(:fake_data) do
        [
            double(blocked_issue_id: 1745, count: 1.0),
            nil # nil for unblocked issues
        ]
      end

      before do
        expect(issue_link).to receive(:blocked_issuables_for_collection).and_return(fake_data)
      end

      it 'clears the pending IDs' do
        subject.block_aggregate

        expect(subject.lazy_state[:pending_ids]).to be_empty
      end
    end
  end
end
