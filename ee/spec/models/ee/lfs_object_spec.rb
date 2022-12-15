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

  describe '.search' do
    let_it_be(:lfs_object1) { create(:lfs_object) }
    let_it_be(:lfs_object2) { create(:lfs_object) }
    let_it_be(:lfs_object3) { create(:lfs_object) }

    context 'when search query is empty' do
      it 'returns all records' do
        result = described_class.search('')

        expect(result).to contain_exactly(lfs_object1, lfs_object2, lfs_object3)
      end
    end

    context 'when search query is not empty' do
      context 'without matches' do
        it 'filters all lfs objects' do
          result = described_class.search('something_that_does_not_exist')

          expect(result).to be_empty
        end
      end

      context 'with matches by attributes' do
        context 'for file attribute' do
          before do
            lfs_object1.update_column(:file, 'a1e7550e9b718dafc9b525a04879a766de62e4fbdfc46593d47f7ab74636')
            lfs_object2.update_column(:file, '4c6fe7a2979eefb9ec74a5dfc6888fb25543cf99b77586b79afea1da6f97')
            lfs_object3.update_column(:file, '8de917525f83104736f6c64d32f0e2a02f5bf2ee57843a54f222cba8c813')
          end

          it do
            result = described_class.search('8de917525f83104736f6c64d32f0e2a02f5bf2ee57843a54f222cba8c813')

            expect(result).to contain_exactly(lfs_object3)
          end
        end
      end
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
