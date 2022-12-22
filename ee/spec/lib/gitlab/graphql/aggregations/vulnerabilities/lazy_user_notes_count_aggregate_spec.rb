# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::Aggregations::Vulnerabilities::LazyUserNotesCountAggregate, feature_category: :vulnerability_management do
  let(:query_ctx) do
    {}
  end

  let(:vulnerability) { create(:vulnerability) }

  describe '#initialize' do
    it 'adds the vulnerability to the lazy state' do
      subject = described_class.new(query_ctx, vulnerability)

      expect(subject.lazy_state[:pending_vulnerability_ids]).to match [vulnerability.id]
      expect(subject.vulnerability).to match vulnerability
    end

    it 'uses lazy_user_notes_count_aggregate to collect aggregates' do
      subject = described_class.new({ lazy_user_notes_count_aggregate: { pending_vulnerability_ids: [10, 20, 30].to_set, loaded_objects: {} } }, vulnerability)

      expect(subject.lazy_state[:pending_vulnerability_ids]).to match_array [10, 20, 30, vulnerability.id]
      expect(subject.vulnerability).to match vulnerability
    end
  end

  describe '#execute' do
    subject { described_class.new(query_ctx, vulnerability) }

    before do
      subject.instance_variable_set(:@lazy_state, fake_state)
    end

    context 'if the record has already been loaded' do
      let(:fake_state) do
        { pending_vulnerability_ids: Set.new, loaded_objects: { vulnerability.id => 10 } }
      end

      it 'does not make the query again' do
        expect(::Note).not_to receive(:user)

        subject.execute
      end
    end

    context 'if the record has not been loaded' do
      let(:other_vulnerability) { create(:vulnerability) }
      let(:fake_state) do
        { pending_vulnerability_ids: Set.new([vulnerability.id, other_vulnerability.id]), loaded_objects: {} }
      end

      let(:fake_data) do
        {
          vulnerability.id => 10,
          other_vulnerability.id => 14
        }
      end

      before do
        allow(::Note).to receive_message_chain(:user, :count_for_vulnerability_id).and_return(fake_data)
      end

      it 'makes the query' do
        expect(::Note).to receive_message_chain(:user, :count_for_vulnerability_id).with([vulnerability.id, other_vulnerability.id])

        subject.execute
      end

      it 'clears the pending IDs' do
        subject.execute

        expect(subject.lazy_state[:pending_vulnerability_ids]).to be_empty
      end
    end
  end
end
