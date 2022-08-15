# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Database::BatchedBackgroundMigrationsFinder do
  let!(:migration_1) { create(:batched_background_migration, created_at: Time.now - 2) }
  let!(:migration_2) { create(:batched_background_migration, created_at: Time.now - 1) }
  let!(:migration_3) { create(:batched_background_migration, created_at: Time.now - 3) }

  let(:finder) { described_class.new(database: database) }

  describe '#execute' do
    let(:database) { :main }

    subject { finder.execute }

    it 'returns migrations order by created_at (DESC)' do
      is_expected.to eq([migration_2, migration_1, migration_3])
    end

    it 'limits the number of returned migrations' do
      stub_const('Database::BatchedBackgroundMigrationsFinder::RETURNED_MIGRATIONS', 2)

      is_expected.to eq([migration_2, migration_1])
    end

    context 'when multiple database is enabled', :add_ci_connection do
      let(:db_config) { instance_double(ActiveRecord::DatabaseConfigurations::HashConfig, name: 'fake_db') }
      let(:database) { :ci }
      let(:base_models) { { 'fake_db' => default_model, 'ci' => ci_model }.with_indifferent_access }
      let(:ci_model) { Ci::ApplicationRecord }
      let(:default_model) { ActiveRecord::Base }

      before do
        allow(Gitlab::Database).to receive(:db_config_for_connection).and_return(db_config)
        allow(Gitlab::Database).to receive(:database_base_models).and_return(base_models)
      end

      context 'when CI database is provided' do
        it "uses CI database connection" do
          expect(Gitlab::Database::SharedModel).to receive(:using_connection).with(ci_model.connection).and_yield

          subject
        end

        it 'returns CI database records' do
          # If we only have one DB we'll see both migrations
          skip_if_multiple_databases_not_setup

          ci_database_migration = Gitlab::Database::SharedModel.using_connection(ci_model.connection) do
            create(:batched_background_migration, :active, gitlab_schema: 'gitlab_ci')
          end

          is_expected.to eq([ci_database_migration])
        end
      end
    end
  end
end
