# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::PackageFileRegistry, :geo, type: :model, feature_category: :geo_replication do
  include ::EE::GeoHelpers

  it_behaves_like 'a BulkInsertSafe model', described_class do
    let(:valid_items_for_bulk_insertion) { build_list(:geo_package_file_registry, 10, package_file: create(:package_file, :npm), created_at: Time.zone.now) }
    let(:invalid_items_for_bulk_insertion) { [] } # class does not have any validations defined
  end

  include_examples 'a Geo framework registry'
  include_examples 'a Geo searchable registry'

  describe '.find_registry_differences' do
    let(:synced_group) { create(:group) }
    let(:synced_subgroup) { create(:group, parent: synced_group) }
    let(:unsynced_group) { create(:group) }

    let(:synced_project) { create(:project, group: synced_group) }
    let(:synced_project_in_nested_group) { create(:project, group: synced_subgroup) }
    let(:project_on_broken_shard) { create(:project, :broken_storage, group: unsynced_group) }

    let!(:package_file) { create(:conan_package_file, :conan_package) }

    subject { described_class }

    before do
      stub_current_geo_node(secondary)

      create(:geo_package_file_registry, package_file_id: package_file.id)
      create(:geo_package_file_registry, package_file_id: non_existing_record_id)
    end

    context 'with selective sync disabled' do
      let(:secondary) { create(:geo_node) }

      it 'finds unused and untracked items' do
        package_file1 = create(:conan_package_file, :conan_package)

        range = 1..non_existing_record_id

        untracked, unused = subject.find_registry_differences(range)

        expect(untracked).to match_array([package_file1.id])
        expect(unused).to match_array([non_existing_record_id])
      end
    end

    context 'with selective sync by shard' do
      let(:secondary) { create(:geo_node, selective_sync_type: 'shards', selective_sync_shards: ['broken']) }

      it 'finds unused and untracked items' do
        package = create(:conan_package, without_package_files: true, project: project_on_broken_shard)
        package_file1 = create(:conan_package_file, :conan_package, package: package)

        range = 1..non_existing_record_id

        untracked, unused = subject.find_registry_differences(range)

        expect(untracked).to match_array([package_file1.id])
        expect(unused).to match_array([non_existing_record_id, package_file.id])
      end
    end

    context 'with selective sync by namespace' do
      let(:secondary) { create(:geo_node, selective_sync_type: 'namespaces', namespaces: [synced_group]) }

      it 'finds unused and untracked items' do
        package = create(:conan_package, without_package_files: true, project: synced_project)
        package_file1 = create(:conan_package_file, :conan_package, package: package)

        range = 1..non_existing_record_id

        untracked, unused = subject.find_registry_differences(range)

        expect(untracked).to match_array([package_file1.id])
        expect(unused).to match_array([package_file.id, non_existing_record_id])
      end
    end
  end
end
