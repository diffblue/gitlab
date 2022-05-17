# frozen_string_literal: true

RSpec.shared_examples 'issuable lazy block aggregate' do
  let(:query_ctx) do
    {}
  end

  describe '#initialize' do
    it 'adds the issuable_id to the lazy state' do
      subject = described_class.new(query_ctx, issuable_id)

      expect(subject.lazy_state[:pending_ids]).to match_array [issuable_id]
      expect(subject.issuable_id).to match issuable_id
    end
  end

  describe '#block_aggregate' do
    subject { described_class.new(query_ctx, issuable_id) }

    let(:fake_state) do
      { pending_ids: Set.new, loaded_objects: {} }
    end

    before do
      subject.instance_variable_set(:@lazy_state, fake_state)
    end

    context 'when there is a block provided' do
      subject do
        described_class.new(query_ctx, issuable_id) do |result|
          result.do_thing
        end
      end

      it 'calls the block' do
        expect(fake_state[:loaded_objects][issuable_id]).to receive(:do_thing)

        subject.block_aggregate
      end
    end

    context 'if the record has already been loaded' do
      let(:fake_state) do
        { pending_ids: Set.new, loaded_objects: { issuable_id => class_double(issuable_link_class, count: 10) } }
      end

      it 'does not make the query again' do
        expect(issuable_link_class).not_to receive(:blocked_issuables_for_collection)

        subject.block_aggregate
      end
    end

    context 'if the record has not been loaded' do
      let(:fake_state) do
        { pending_ids: Set.new([issuable_id]), loaded_objects: {} }
      end

      before do
        expect(issuable_link_class).to receive(:blocked_issuables_for_collection).and_return(fake_data)
      end

      it 'clears the pending IDs' do
        subject.block_aggregate

        expect(subject.lazy_state[:pending_ids]).to be_empty
      end
    end
  end
end
