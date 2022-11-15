# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DependencyProxy::Blob do
  include EE::GeoHelpers

  include_examples 'a replicable model with a separate table for verification state' do
    before do
      stub_dependency_proxy_setting(enabled: true)
      stub_dependency_proxy_object_storage
    end

    let(:verifiable_model_record) { build(:dependency_proxy_blob) }
    let(:unverifiable_model_record) { build(:dependency_proxy_blob, :remote_store) }
  end

  describe '#replicables_for_current_secondary' do
    let(:model) { create(:group) }
    let(:blob_with_model_group) { create(:dependency_proxy_blob, group: model) }
    let(:blob_without_model_group) { create(:dependency_proxy_blob) }

    before do
      stub_current_geo_node(node)
    end

    where(:object_storage_sync_enabled) do
      [
        true,
        false
      ]
    end

    with_them do
      context 'without selective sync' do
        let(:node) { create(:geo_node) }

        it 'includes everything' do
          [blob_with_model_group, blob_without_model_group].each do |blob|
            expect(described_class.replicables_for_current_secondary(blob).exists?).to be(true)
          end
        end

        context 'with selective sync' do
          context 'with namespaces' do
            let(:node) do
              create(
                :geo_node_with_selective_sync_for,
                model: model,
                namespaces: :model,
                sync_object_storage: object_storage_sync_enabled
              )
            end

            it 'sync blobs in the group' do
              expect(described_class.replicables_for_current_secondary(blob_with_model_group).exists?).to be(true)
            end

            it 'does not sync blobs in other groups' do
              expect(described_class.replicables_for_current_secondary(blob_without_model_group).exists?).to be(false)
            end
          end

          context 'with shards' do
            let(:blob_with_project_in_group) { create(:dependency_proxy_blob, group: model) }
            let(:blob_without_project_in_group) { create(:dependency_proxy_blob) }
            let(:node) do
              create(:geo_node_with_selective_sync_for,
                     model: model,
                     shards: :model_project,
                     sync_object_storage: object_storage_sync_enabled
                    )
            end

            it 'syncs blobs associated with projects contained in the group' do
              expect(described_class.replicables_for_current_secondary(blob_with_project_in_group).exists?).to be(true)
            end

            it 'does not sync blobs not associated with projects outside the group' do
              expect(described_class.replicables_for_current_secondary(blob_without_project_in_group).exists?)
                .to be(false)
            end
          end
        end
      end
    end
  end
end
