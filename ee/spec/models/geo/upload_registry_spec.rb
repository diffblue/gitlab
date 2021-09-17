# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::UploadRegistry, :geo do
  include EE::GeoHelpers

  before do
    stub_feature_flags(geo_upload_replication: false)
  end

  it_behaves_like 'a BulkInsertSafe model', Geo::UploadRegistry do
    let(:valid_items_for_bulk_insertion) { build_list(:geo_upload_legacy_registry, 10, created_at: Time.zone.now) }
    let(:invalid_items_for_bulk_insertion) { [] } # class does not have any validations defined
  end

  it 'finds associated Upload record' do
    registry = create(:geo_upload_legacy_registry, :attachment, :with_file)

    expect(described_class.find(registry.id).upload).to be_an_instance_of(Upload)
  end

  describe '.find_registry_differences' do
    let_it_be(:secondary) { create(:geo_node) }
    let_it_be(:project) { create(:project) }
    let_it_be(:upload_1) { create(:upload, model: project) }
    let_it_be(:upload_2) { create(:upload, model: project) }
    let_it_be(:upload_3) { create(:upload, :issuable_upload, model: project) }
    let_it_be(:upload_4) { create(:upload, model: project) }
    let_it_be(:upload_5) { create(:upload, model: project) }
    let_it_be(:upload_6) { create(:upload, :personal_snippet_upload) }
    let_it_be(:upload_7) { create(:upload, :object_storage, model: project) }
    let_it_be(:upload_8) { create(:upload, :object_storage, model: project) }
    let_it_be(:upload_9) { create(:upload, :object_storage, model: project) }

    before do
      stub_current_geo_node(secondary)
    end

    it 'returns untracked IDs as well as tracked IDs that are unused', :aggregate_failures do
      max_id = Upload.maximum(:id)
      create(:geo_upload_legacy_registry, :avatar, file_id: upload_1.id)
      create(:geo_upload_legacy_registry, :file, file_id: upload_3.id)
      create(:geo_upload_legacy_registry, :avatar, file_id: upload_5.id)
      create(:geo_upload_legacy_registry, :personal_file, file_id: upload_6.id)
      create(:geo_upload_legacy_registry, :avatar, file_id: upload_7.id)
      unused_registry_1 = create(:geo_upload_legacy_registry, :attachment, file_id: max_id + 1)
      unused_registry_2 = create(:geo_upload_legacy_registry, :personal_file, file_id: max_id + 2)
      range = 1..(max_id + 2)

      untracked, unused = described_class.find_registry_differences(range)

      expected_untracked = [
        [upload_2.id, 'avatar'],
        [upload_4.id, 'avatar'],
        [upload_8.id, 'avatar'],
        [upload_9.id, 'avatar']
      ]

      expected_unused = [
        [unused_registry_1.file_id, 'attachment'],
        [unused_registry_2.file_id, 'personal_file']
      ]

      expect(untracked).to match_array(expected_untracked)
      expect(unused).to match_array(expected_unused)
    end
  end

  describe '.failed' do
    it 'returns registries in the failed state' do
      failed = create(:geo_upload_legacy_registry, :failed)
      create(:geo_upload_legacy_registry)

      expect(described_class.failed).to match_ids(failed)
    end
  end

  describe '.synced' do
    it 'returns registries in the synced state' do
      create(:geo_upload_legacy_registry, :failed)
      synced = create(:geo_upload_legacy_registry)

      expect(described_class.synced).to match_ids(synced)
    end
  end

  describe '.retry_due' do
    it 'returns registries in the synced state' do
      failed = create(:geo_upload_legacy_registry, :failed)
      synced = create(:geo_upload_legacy_registry)
      retry_yesterday = create(:geo_upload_legacy_registry, retry_at: Date.yesterday)
      create(:geo_upload_legacy_registry, retry_at: Date.tomorrow)

      expect(described_class.retry_due).to match_ids([failed, synced, retry_yesterday])
    end
  end

  describe '.never_attempted_sync' do
    it 'returns registries that are never synced' do
      create(:geo_upload_legacy_registry, :failed)
      create(:geo_upload_legacy_registry)
      pending = create(:geo_upload_legacy_registry, retry_count: nil, success: false)

      expect(described_class.never_attempted_sync).to match_ids([pending])
    end
  end

  describe '.with_status' do
    it 'finds the registries with status "synced"' do
      expect(described_class).to receive(:synced)

      described_class.with_status('synced')
    end

    it 'finds the registries with status "never_attempted_sync" when filter is set to "pending"' do
      expect(described_class).to receive(:never_attempted_sync)

      described_class.with_status('pending')
    end

    it 'finds the registries with status "failed"' do
      expect(described_class).to receive(:failed)

      described_class.with_status('failed')
    end
  end

  describe '.with_search' do
    it 'searches registries on path' do
      upload = create(:upload, path: 'uploads/-/system/project/avatar/my-awesome-avatar.png')
      upload_registry = create(:geo_upload_legacy_registry, file_id: upload.id, file_type: :avatar)

      expect(described_class.with_search('awesome-avatar')).to match_ids(upload_registry)
    end
  end

  describe '#file' do
    it 'returns the path of the upload of a registry' do
      upload = create(:upload, :with_file)
      registry = create(:geo_upload_legacy_registry, :file, file_id: upload.id)

      expect(registry.file).to eq(upload.path)
    end

    it 'return "removed" message when the upload no longer exists' do
      registry = create(:geo_upload_legacy_registry, :avatar)

      expect(registry.file).to match(/^Removed avatar with id/)
    end
  end

  describe '#synchronization_state' do
    let_it_be(:failed) { create(:geo_upload_legacy_registry, :failed) }
    let_it_be(:synced) { create(:geo_upload_legacy_registry) }

    it 'returns :synced for a successful synced registry' do
      expect(synced.synchronization_state).to eq(:synced)
    end

    it 'returns :never for a successful registry never synced' do
      never = build(:geo_upload_legacy_registry, success: false, retry_count: nil)

      expect(never.synchronization_state).to eq(:never)
    end

    it 'returns :failed for a failed registry' do
      expect(failed.synchronization_state).to eq(:failed)
    end
  end
end

RSpec.describe Geo::UploadRegistry, :geo, type: :model do
  let_it_be(:registry) { create(:geo_upload_registry) }

  specify 'factory is valid' do
    expect(registry).to be_valid
  end

  include_examples 'a Geo framework registry'
end
