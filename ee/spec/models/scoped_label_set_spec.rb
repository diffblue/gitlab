# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ScopedLabelSet, feature_category: :portfolio_management do
  let_it_be(:kv_label1) { create(:label, title: 'key::label1') }
  let_it_be(:kv_label2) { create(:label, title: 'key::label2') }
  let_it_be(:kv_label3) { create(:label, title: 'key::label3', lock_on_merge: true) }

  describe '.from_label_ids' do
    def get_labels(sets, key)
      sets.find { |set| set.key == key }.label_ids
    end

    it 'groups labels by their key' do
      labels = [
        create(:label, title: 'label1'),
        create(:label, title: 'label2'),
        create(:label, title: 'key::label1'),
        create(:label, title: 'key::label2'),
        create(:label, title: 'key::another key::label1'),
        create(:label, title: 'key::another key::label2')
      ]

      sets = described_class.from_label_ids(labels)

      expect(sets.size).to eq 3
      expect(get_labels(sets, nil)).to match_array([labels[0].id, labels[1].id])
      expect(get_labels(sets, 'key')).to match_array([labels[2].id, labels[3].id])
      expect(get_labels(sets, 'key::another key')).to match_array([labels[4].id, labels[5].id])
    end
  end

  describe '#valid?' do
    it 'returns true for not scoped labels' do
      label1 = build(:label, title: 'label1')
      label2 = build(:label, title: 'label2')

      set = described_class.new(nil, [label1, label2])

      expect(set.valid?).to eq(true)
    end

    it 'returns true for scoped labels with single label' do
      set = described_class.new(nil, [kv_label1])

      expect(set.valid?).to eq(true)
    end

    it 'returns false for scoped labels with multiple labels' do
      set = described_class.new('key', [kv_label1, kv_label2])

      expect(set.valid?).to eq(false)
    end
  end

  describe '#add' do
    it 'adds a label to the set' do
      set = described_class.new('key')

      set.add(kv_label1)

      expect(set.labels).to eq([kv_label1])
    end
  end

  describe '#contains_any?' do
    it 'returns true if any of label ids is in set' do
      set = described_class.new('key', [kv_label1, kv_label2])

      expect(set.contains_any?([kv_label2.id])).to eq(true)
    end

    it 'returns false if certain label ids is not in set' do
      set = described_class.new('key', [kv_label1])

      expect(set.contains_any?([kv_label2.id])).to eq(false)
    end
  end

  describe '#last_id_by_order' do
    it 'returns last label present in the set ordered by custom order of superset of label ids' do
      set = described_class.new('key', [kv_label1, kv_label3])

      expect(set.last_id_by_order([kv_label1.id, kv_label3.id, kv_label2.id])).to eq(kv_label3.id)
    end

    it 'returns last label present in the set ordered by custom order if there is single item' do
      set = described_class.new('key', [kv_label1, kv_label3])

      expect(set.last_id_by_order([kv_label3.id])).to eq(kv_label3.id)
    end
  end

  describe '#lock_on_merge_labels?' do
    it 'does not detect any locked labels' do
      set = described_class.new('key', [kv_label1, kv_label2])

      expect(set.lock_on_merge_labels?).to be_falsey
    end

    it 'detects locked labels' do
      set = described_class.new('key', [kv_label1, kv_label2, kv_label3])

      expect(set.lock_on_merge_labels?).to be_truthy
    end
  end
end
