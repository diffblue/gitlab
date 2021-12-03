# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Upload do
  include EE::GeoHelpers
  using RSpec::Parameterized::TableSyntax

  it { is_expected.to have_one(:upload_state).inverse_of(:upload).class_name('Geo::UploadState') }

  include_examples 'a replicable model with a separate table for verification state' do
    let(:verifiable_model_record) { build(:upload) }
    let(:unverifiable_model_record) { build(:upload, store: ObjectStorage::Store::REMOTE) }
  end

  describe '.replicables_for_current_secondary' do
    # Selective sync is configured relative to the upload's model. Take care not
    # to specify a model_factory that contradicts factory.
    #
    # Permutations of sync_object_storage combined with object-stored-uploads
    # are tested in code, because the logic is simple, and to do it in the table
    # would quadruple its size and have too much duplication.
    where(:selective_sync_namespaces, :selective_sync_shards, :factory, :model_factory, :is_upload_included) do
      nil                  | nil            | [:upload]                    | [:project]               | true
      nil                  | nil            | [:upload, :issuable_upload]  | [:project]               | true
      nil                  | nil            | [:upload, :namespace_upload] | [:group]                 | true
      nil                  | nil            | [:upload, :favicon_upload]   | [:appearance]            | true
      # selective sync by shard
      nil                  | :model         | [:upload]                    | [:project]               | true
      nil                  | :other         | [:upload]                    | [:project]               | false
      nil                  | :model_project | [:upload, :namespace_upload] | [:group]                 | true
      nil                  | :other         | [:upload, :namespace_upload] | [:group]                 | false
      nil                  | :other         | [:upload, :favicon_upload]   | [:appearance]            | true
      # selective sync by namespace
      :model_parent        | nil            | [:upload]                    | [:project]               | true
      :model_parent_parent | nil            | [:upload]                    | [:project, :in_subgroup] | true
      :model               | nil            | [:upload, :namespace_upload] | [:group]                 | true
      :model_parent        | nil            | [:upload, :namespace_upload] | [:group, :nested]        | true
      :other               | nil            | [:upload]                    | [:project]               | false
      :other               | nil            | [:upload]                    | [:project, :in_subgroup] | false
      :other               | nil            | [:upload, :namespace_upload] | [:group]                 | false
      :other               | nil            | [:upload, :namespace_upload] | [:group, :nested]        | false
      :other               | nil            | [:upload, :favicon_upload]   | [:appearance]            | true
    end

    with_them do
      subject(:upload_included) { described_class.replicables_for_current_secondary(upload).exists? }

      let(:model) { create(*model_factory) } # rubocop:disable Rails/SaveBang
      let(:node) do
        create(:geo_node_with_selective_sync_for,
               model: model,
               namespaces: selective_sync_namespaces,
               shards: selective_sync_shards,
               sync_object_storage: sync_object_storage)
      end

      before do
        stub_current_geo_node(node)
      end

      context 'when sync object storage is enabled' do
        let(:sync_object_storage) { true }

        context 'when the upload is locally stored' do
          let(:upload) { create(*factory, model: model) }

          it { is_expected.to eq(is_upload_included) }
        end

        context 'when the upload is object stored' do
          let(:upload) { create(*factory, :object_storage, model: model) }

          it { is_expected.to eq(is_upload_included) }
        end
      end

      context 'when sync object storage is disabled' do
        let(:sync_object_storage) { false }

        context 'when the upload is locally stored' do
          let(:upload) { create(*factory, model: model) }

          it { is_expected.to eq(is_upload_included) }
        end

        context 'when the upload is object stored' do
          let(:upload) { create(*factory, :object_storage, model: model) }

          it { is_expected.to be_falsey }
        end
      end
    end
  end

  describe '#destroy' do
    subject { create(:upload, :namespace_upload, checksum: '8710d2c16809c79fee211a9693b64038a8aae99561bc86ce98a9b46b45677fe4') }

    context 'when running in a Geo primary node' do
      let_it_be(:primary) { create(:geo_node, :primary) }
      let_it_be(:secondary) { create(:geo_node) }

      it 'logs an event to the Geo event log when bulk removal is used', :sidekiq_inline do
        stub_current_geo_node(primary)

        expect { subject.model.destroy! }.to change(Geo::Event.where(replicable_name: :upload, event_name: :deleted), :count).by(1)

        payload = Geo::Event.where(replicable_name: :upload, event_name: :deleted).last.payload

        expect(payload['model_record_id']).to eq(subject.id)
        expect(payload['blob_path']).to eq(subject.relative_path)
        expect(payload['uploader_class']).to eq('NamespaceFileUploader')
      end
    end
  end
end
