# frozen_string_literal: true

RSpec.shared_examples 'issuable lazy links aggregate' do
  let(:query_ctx) do
    {}
  end

  describe '#initialize' do
    it 'adds the issuable_id to the `blocked` lazy state by default' do
      subject = described_class.new(query_ctx, issuable_id)

      expect(subject.lazy_state[:pending_ids]['blocked']).to match_array [issuable_id]
      expect(subject.issuable_id).to match issuable_id
    end
  end

  describe '#links_aggregate' do
    subject { described_class.new(query_ctx, issuable_id, link_type: link_type) }

    let(:fake_state) do
      {
        pending_ids: { 'blocked' => Set.new, 'blocking' => Set.new },
        loaded_objects: { 'blocked' => {}, 'blocking' => {} }
      }
    end

    before do
      subject.instance_variable_set(:@lazy_state, fake_state)
    end

    shared_examples 'block provided' do
      subject do
        described_class.new(query_ctx, issuable_id, link_type: link_type) do |result|
          result.do_thing
        end
      end

      it 'calls the block' do
        expect(fake_state[:loaded_objects][link_type][issuable_id]).to receive(:do_thing)

        subject.links_aggregate
      end
    end

    shared_examples 'the record has already been loaded' do
      it 'does not make the query again' do
        expect(issuable_link_class).not_to receive(:"#{link_type}_issuables_for_collection")

        subject.links_aggregate
      end
    end

    shared_examples 'the record has not been loaded' do
      let(:fake_data) { link_type == 'blocked' ? fake_blocked_data : fake_blocking_data }

      before do
        expect(issuable_link_class).to receive(:"#{link_type}_issuables_for_collection").and_return(fake_data)
      end

      it 'clears the pending IDs' do
        subject.links_aggregate

        expect(subject.lazy_state[:pending_ids][link_type]).to be_empty
      end
    end

    context 'when link_type is `blocked`' do
      let(:link_type) { 'blocked' }

      it_behaves_like 'block provided'

      it_behaves_like 'the record has already been loaded' do
        let(:fake_state) do
          {
            pending_ids: { 'blocked' => Set.new, 'blocking' => Set.new },
            loaded_objects: {
              'blocked' => { issuable_id => class_double(issuable_link_class, count: 10) },
              'blocking' => {}
            }
          }
        end
      end

      it_behaves_like 'the record has not been loaded' do
        let(:fake_state) do
          {
            pending_ids: { 'blocked' => Set.new([issuable_id]), 'blocking' => Set.new },
            loaded_objects: { 'blocked' => {}, 'blocking' => {} }
          }
        end
      end
    end

    context 'when link_type is `blocking`' do
      let(:link_type) { 'blocking' }

      it_behaves_like 'block provided'

      it_behaves_like 'the record has already been loaded' do
        let(:fake_state) do
          {
            pending_ids: { 'blocked' => Set.new, 'blocking' => Set.new },
            loaded_objects: {
              'blocked' => {},
              'blocking' => { issuable_id => class_double(issuable_link_class, count: 5) }
            }
          }
        end
      end

      it_behaves_like 'the record has not been loaded' do
        let(:fake_state) do
          {
            pending_ids: { 'blocked' => Set.new, 'blocking' => Set.new([issuable_id]) },
            loaded_objects: { 'blocked' => {}, 'blocking' => {} }
          }
        end
      end
    end
  end
end
