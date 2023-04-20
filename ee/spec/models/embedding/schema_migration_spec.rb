# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Embedding::SchemaMigration, feature_category: :database do
  describe '.all_versions' do
    subject { described_class.all_versions }

    it 'returns all versions' do
      allow(described_class).to receive(:order).with(:version).and_return([{ version: '2' }, { version: '1' }])

      expect(subject).to eq %w[2 1]
    end
  end
end
