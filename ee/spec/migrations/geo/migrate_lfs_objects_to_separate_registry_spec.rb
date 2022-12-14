# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe MigrateLfsObjectsToSeparateRegistry, :geo, feature_category: :geo_replication do
  let(:file_registry) { table(:file_registry) }
  let(:lfs_object_registry) { table(:lfs_object_registry) }

  before do
    file_registry.create!(file_id: 1, file_type: 'lfs', success: true, bytes: 1024, sha256: '0' * 64)
    file_registry.create!(file_id: 2, file_type: 'lfs', success: false, bytes: 2048, sha256: '1' * 64)
    file_registry.create!(file_id: 3, file_type: 'attachment', success: true)
    file_registry.create!(file_id: 4, file_type: 'lfs', success: false, bytes: 4096, sha256: '2' * 64)
  end

  describe '#up' do
    it 'migrates all file registries for LFS objects to its own data table' do
      expect(file_registry.all.count).to eq(4)

      migrate!

      expect(file_registry.all.count).to eq(4)
      expect(lfs_object_registry.all.count).to eq(3)

      expect(lfs_object_registry.where(lfs_object_id: 1, success: true, bytes: 1024, sha256: '0' * 64).count).to eq(1)
      expect(lfs_object_registry.where(lfs_object_id: 2, success: false, bytes: 2048, sha256: '1' * 64).count).to eq(1)
      expect(lfs_object_registry.where(lfs_object_id: 4, success: false, bytes: 4096, sha256: '2' * 64).count).to eq(1)
      expect(file_registry.where(file_id: 3, file_type: 'attachment', success: true).count).to eq(1)
    end

    it 'creates a new lfs object registry with the trigger' do
      migrate!

      expect(lfs_object_registry.all.count).to eq(3)

      file_registry.create!(file_id: 5, file_type: 'lfs', success: true, bytes: 8192, sha256: '3' * 64)

      expect(lfs_object_registry.all.count).to eq(4)
      expect(lfs_object_registry.where(lfs_object_id: 5, success: true, bytes: 8192, sha256: '3' * 64).count).to eq(1)
    end

    it 'updates a new lfs object with the trigger' do
      migrate!

      expect(lfs_object_registry.all.count).to eq(3)

      entry = file_registry.find_by(file_id: 1)
      entry.update!(success: false, bytes: 10240, sha256: '10' * 64)

      expect(lfs_object_registry.where(lfs_object_id: 1, success: false, bytes: 10240, sha256: '10' * 64).count).to eq(1)
      # Ensure that *only* the correct lfs object is updated
      expect(lfs_object_registry.find_by(lfs_object_id: 2).bytes).to eq(2048)
    end

    it 'creates a new lfs object using the next ID' do
      migrate!

      max_id = lfs_object_registry.maximum(:id)
      last_id = lfs_object_registry.create!(lfs_object_id: 5, success: true).id

      expect(last_id - max_id).to eq(1)
    end
  end

  describe '#down' do
    it 'rolls back data properly' do
      migrate!

      expect(file_registry.all.count).to eq(4)
      expect(lfs_object_registry.all.count).to eq(3)

      schema_migrate_down!

      expect(file_registry.all.count).to eq(4)
      expect(file_registry.where(file_type: 'attachment').count).to eq(1)
      expect(file_registry.where(file_type: 'lfs').count).to eq(3)

      expect(file_registry.where(file_type: 'lfs', bytes: 1024, sha256: '0' * 64).count).to eq(1)
      expect(file_registry.where(file_type: 'lfs', bytes: 2048, sha256: '1' * 64).count).to eq(1)
      expect(file_registry.where(file_type: 'lfs', bytes: 4096, sha256: '2' * 64).count).to eq(1)
    end
  end
end
