# frozen_string_literal: true

RSpec.shared_examples 'issuables that can block or be blocked' do
  describe '.issuable_type' do
    it { expect(described_class.issuable_type).to eq(issuable_type) }
  end

  describe '.inverse_link_type' do
    it 'returns the inverse type of link' do
      expect(described_class.inverse_link_type('relates_to')).to eq('relates_to')
      expect(described_class.inverse_link_type('is_blocked_by')).to eq('is_blocked_by')
      expect(described_class.inverse_link_type('blocks')).to eq('is_blocked_by')
    end
  end

  describe '.blocked_issuable_ids' do
    it 'returns only ids of issues which are blocked' do
      link1 = create(factory_class, link_type: ::IssuableLink::TYPE_BLOCKS)
      link2 = create(factory_class, link_type: ::IssuableLink::TYPE_RELATES_TO)
      link3 = create(factory_class, source: create(issuable_type, :closed), link_type: ::IssuableLink::TYPE_BLOCKS)

      expect(described_class.blocked_issuable_ids([link1.target_id, link2.source_id, link3.target_id]))
        .to match_array([link1.target_id])
    end
  end

  describe '.blocking_issuables_ids_for' do
    it 'returns blocking issuables ids' do
      create(factory_class, source: blocking_issuable_1, target: blocked_issuable_1, link_type: ::IssuableLink::TYPE_BLOCKS)
      create(factory_class, source: blocking_issuable_2, target: blocked_issuable_1, link_type: ::IssuableLink::TYPE_BLOCKS)

      blocking_ids = described_class.blocking_issuables_ids_for(blocked_issuable_1)

      expect(blocking_ids).to match_array([blocking_issuable_1.id, blocking_issuable_2.id])
    end
  end

  context 'blocking issuables count' do
    before_all do
      create(factory_class, source: blocking_issuable_1, target: blocked_issuable_1, link_type: ::IssuableLink::TYPE_BLOCKS)
      create(factory_class, source: blocking_issuable_1, target: blocked_issuable_2, link_type: ::IssuableLink::TYPE_BLOCKS)
      create(factory_class, source: blocking_issuable_2, target: blocked_issuable_3, link_type: ::IssuableLink::TYPE_BLOCKS)
    end

    describe '.blocking_issuables_for_collection' do
      it 'returns blocking issues count grouped by issue id' do
        grouping_row = "blocking_#{issuable_type}_id"

        results = described_class.blocking_issuables_for_collection([blocking_issuable_1, blocking_issuable_2])

        expect(results.find { |link| link[grouping_row] == blocking_issuable_1.id }.count).to eq(2)
        expect(results.find { |link| link[grouping_row] == blocking_issuable_2.id }.count).to eq(1)
      end
    end

    describe '.blocked_issuables_for_collection' do
      it 'returns blocked issues count grouped by issue id' do
        grouping_row = "blocked_#{issuable_type}_id"

        results = described_class.blocked_issuables_for_collection([blocked_issuable_1, blocked_issuable_2, blocked_issuable_3])

        expect(results.find { |link| link[grouping_row] == blocked_issuable_1.id }.count).to eq(1)
        expect(results.find { |link| link[grouping_row] == blocked_issuable_1.id }.count).to eq(1)
        expect(results.find { |link| link[grouping_row] == blocked_issuable_1.id }.count).to eq(1)
      end
    end

    describe '.blocking_issuables_count_for' do
      it 'returns blocked issues count for single issue' do
        blocking_count = described_class.blocking_issuables_count_for(blocking_issuable_1)

        expect(blocking_count).to eq(2)
      end
    end
  end
end
