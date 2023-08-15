# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::RegistryConsistencyService, :geo, :use_clean_rails_memory_store_caching,
feature_category: :geo_replication do
  include EE::GeoHelpers

  let(:secondary) { create(:geo_node) }

  before do
    stub_current_geo_node(secondary)
    stub_registry_replication_config(enabled: true)
    stub_external_diffs_setting(enabled: true)
  end

  shared_examples 'registry consistency service' do |klass|
    let(:registry_class) { klass }
    let(:registry_class_factory) { registry_factory_name(registry_class) }
    let(:model_class) { registry_class::MODEL_CLASS }
    let(:model_class_factory) { model_class_factory_name(registry_class) }
    let(:model_foreign_key) { registry_class::MODEL_FOREIGN_KEY }
    let(:batch_size) { 2 }

    subject { described_class.new(registry_class, batch_size: batch_size) }

    describe 'registry_class interface' do
      it 'defines a MODEL_CLASS constant' do
        expect(registry_class::MODEL_CLASS).not_to be_nil
      end

      it 'responds to .name' do
        expect(registry_class).to respond_to(:name)
      end

      it 'responds to .insert_for_model_ids' do
        expect(registry_class).to respond_to(:insert_for_model_ids)
      end

      it 'responds to .delete_for_model_ids' do
        expect(registry_class).to respond_to(:delete_for_model_ids)
      end

      it 'responds to .find_registry_differences' do
        expect(registry_class).to respond_to(:find_registry_differences)
      end
    end

    describe '#execute' do
      context 'when there are replicable records missing registries' do
        let!(:expected_batch) { create_list(model_class_factory, batch_size) }

        it 'creates missing registries' do
          expect do
            subject.execute
          end.to change { registry_class.model_id_in(expected_batch).count }.by(batch_size)
        end

        it 'returns truthy' do
          expect(subject.execute).to be_truthy
        end

        it 'does not exceed batch size' do
          not_expected = create(model_class_factory) # rubocop:disable Rails/SaveBang

          subject.execute

          expect(registry_class.model_id_in(not_expected)).to be_none
        end
      end

      context 'when there are unused registries' do
        context 'with no replicable records' do
          let(:records) { create_list(model_class_factory, batch_size) }
          let(:unused_model_ids) { records.map(&:id) }

          let!(:registries) do
            records.map do |record|
              create(registry_class_factory, model_foreign_key => record.id)
            end
          end

          before do
            model_class.where(model_class.primary_key => unused_model_ids).delete_all
          end

          it 'deletes unused registries', :sidekiq_inline do
            subject.execute

            expect(registry_class.where(model_foreign_key => unused_model_ids)).to be_empty
          end

          it 'returns truthy' do
            expect(subject.execute).to be_truthy
          end
        end

        context 'when the unused registry foreign key ids are lower than the first replicable model id' do
          let(:records) { create_list(model_class_factory, batch_size) }
          let(:unused_registry_ids) { [records.first].map(&:id) }

          let!(:registries) do
            records.map do |record|
              create(registry_class_factory, model_foreign_key => record.id)
            end
          end

          before do
            model_class.where(model_class.primary_key => unused_registry_ids).delete_all
          end

          it 'deletes unused registries', :sidekiq_inline do
            subject.execute

            expect(registry_class.where(model_foreign_key => unused_registry_ids)).to be_empty
          end

          it 'returns truthy' do
            expect(subject.execute).to be_truthy
          end
        end

        context 'when the unused registry foreign key ids are greater than the last replicable model id' do
          let(:records) { create_list(model_class_factory, batch_size) }
          let(:unused_registry_ids) { [records.last].map(&:id) }

          let!(:registries) do
            records.map do |record|
              create(registry_class_factory, model_foreign_key => record.id)
            end
          end

          before do
            model_class.where(model_class.primary_key => unused_registry_ids).delete_all
          end

          it 'deletes unused registries', :sidekiq_inline do
            subject.execute

            expect(registry_class.where(model_foreign_key => unused_registry_ids)).to be_empty
          end

          it 'returns truthy' do
            expect(subject.execute).to be_truthy
          end
        end
      end

      context 'when all replicable records have registries' do
        it 'does nothing' do
          create_list(model_class_factory, batch_size)

          subject.execute # create the missing registries

          expect do
            subject.execute
          end.not_to change { registry_class.count }
        end

        it 'returns falsey' do
          create_list(model_class_factory, batch_size)

          subject.execute # create the missing registries

          expect(subject.execute).to be_falsey
        end
      end

      context 'when there are no replicable records' do
        it 'does nothing' do
          expect do
            subject.execute
          end.not_to change { registry_class.count }
        end

        it 'returns falsey' do
          expect(subject.execute).to be_falsey
        end
      end
    end
  end

  ::Geo::Secondary::RegistryConsistencyWorker::REGISTRY_CLASSES.each do |klass|
    it_behaves_like 'registry consistency service', klass
  end
end
