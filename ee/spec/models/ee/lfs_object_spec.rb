# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::LfsObject do
  using RSpec::Parameterized::TableSyntax
  include EE::GeoHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :repository, group: group) }
  let_it_be(:another_project) { create(:project, :repository) }

  it { is_expected.to respond_to(:log_geo_deleted_event) }

  context 'when model_record is part of available_verifiables scope' do
    let(:verifiable_model_record) { build(:lfs_object) }
    let(:verification_state_table_class) { verifiable_model_record.class.verification_state_table_class }

    it 'creates verification details' do
      expect { verifiable_model_record.save! }.to change { verification_state_table_class.count }.by(1)
    end
  end

  describe '.with_files_stored_locally' do
    let_it_be(:lfs_object) { create(:lfs_object, :with_file) }

    it 'includes states with local storage' do
      expect(described_class.with_files_stored_locally).to have_attributes(count: 1)
    end
  end

  describe '.replicables_for_current_secondary' do
    where(:selective_sync_enabled, :object_storage_sync_enabled, :lfs_object_object_storage_enabled, :synced_lfs_objects) do
      true  | true  | false  | 1
      true  | false | false  | 1
      false | true  | false  | 2
      false | false | false  | 2
      true  | true  | true   | 1
      true  | false | true   | 1
      false | true  | true   | 2
      false | false | true   | 2
    end

    with_them do
      let(:secondary) do
        node = build(:geo_node, sync_object_storage: object_storage_sync_enabled)

        if selective_sync_enabled
          node.selective_sync_type = 'namespaces'
          node.namespaces = [group]
        end

        node.save!
        node
      end

      before do
        stub_current_geo_node(secondary)
        stub_lfs_object_storage(uploader: LfsObjectUploader) if lfs_object_object_storage_enabled

        lfs_object_1 = create(:lfs_object, :with_file)
        lfs_object_2 = create(:lfs_object, :with_file)
        create(:lfs_objects_project, lfs_object: lfs_object_1, project: project)
        create(:lfs_objects_project, lfs_object: lfs_object_2, project: another_project)
      end

      it 'returns the proper number of LFS objects' do
        expect(described_class.replicables_for_current_secondary(1..described_class.last.id).count).to eq(synced_lfs_objects)
      end
    end
  end
end
