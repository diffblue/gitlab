# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Wiki, feature_category: :wiki do
  describe '#use_separate_indices?', :elastic do
    context 'if migrate_wikis_to_separate_index is finished' do
      before do
        set_elasticsearch_migration_to(:migrate_wikis_to_separate_index, including: true)
      end

      it 'returns true' do
        expect(described_class.use_separate_indices?).to be true
      end
    end

    context 'if migrate_wikis_to_separate_index is not finished' do
      before do
        set_elasticsearch_migration_to(:migrate_wikis_to_separate_index, including: false)
      end

      it 'returns false' do
        expect(described_class.use_separate_indices?).to be false
      end
    end
  end

  describe '#base_class' do
    it 'returns Wiki' do
      expect(described_class.base_class).to eq described_class
    end
  end
end
