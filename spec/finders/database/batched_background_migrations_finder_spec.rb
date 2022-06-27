# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Database::BatchedBackgroundMigrationsFinder do
  let!(:migration_1) { create(:batched_background_migration) }
  let!(:migration_2) { create(:batched_background_migration) }
  let(:finder) { described_class.new(:main) }

  describe '#execute' do
    subject { finder.execute }

    it 'returns all background migrations in descending order by id' do
      is_expected.to eq([migration_2, migration_1])
    end
  end
end
