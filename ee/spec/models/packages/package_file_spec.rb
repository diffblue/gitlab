# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::PackageFile, type: :model do
  include ::EE::GeoHelpers

  context 'new file' do
    it 'calls checksum worker' do
      stub_primary_node
      allow(Geo::VerificationWorker).to receive(:perform_async)

      package_file = create(:conan_package_file, :conan_recipe_file)

      expect(Geo::VerificationWorker).to have_received(:perform_async).with('package_file', package_file.id)
    end
  end

  describe '.replicables_for_current_secondary' do
    subject { described_class.replicables_for_current_secondary(1..described_class.last.id) }

    it 'returns a package files scope' do
      secondary = create(:geo_node)
      package_file = create(:package_file)
      stub_current_geo_node(secondary)

      expect(subject).to be_an(ActiveRecord::Relation)
      expect(subject).to include(package_file)
    end

    context 'object storage' do
      before do
        stub_current_geo_node(secondary)
        stub_package_file_object_storage
      end

      let_it_be(:local_stored) { create(:package_file) }

      # Cannot let_it_be because it depends on stub_package_file_object_storage
      let!(:object_stored) { create(:package_file, :object_storage) }

      context 'with sync object storage enabled' do
        let_it_be(:secondary) { create(:geo_node, sync_object_storage: true) }

        it 'includes local stored and object stored records' do
          expect(subject).to include(local_stored)
          expect(subject).to include(object_stored)
        end
      end

      context 'with sync object storage disabled' do
        let_it_be(:secondary) { create(:geo_node, sync_object_storage: false) }

        it 'includes local stored and excludes object stored records' do
          expect(subject).to include(local_stored)
          expect(subject).not_to include(object_stored)
        end
      end
    end

    context 'selective sync' do
      # Create a package file owned by a project on shard foo
      let_it_be(:project_on_shard_foo) { create_project_on_shard('foo') }
      let_it_be(:package_on_shard_foo) { create(:conan_package, without_package_files: true, project: project_on_shard_foo) }
      let_it_be(:package_file_on_shard_foo) { create(:conan_package_file, package: package_on_shard_foo) }

      # Create a package file owned by a project on shard bar
      let_it_be(:project_on_shard_bar) { create_project_on_shard('bar') }
      let_it_be(:package_on_shard_bar) { create(:conan_package, without_package_files: true, project: project_on_shard_bar) }
      let_it_be(:package_file_on_shard_bar) { create(:conan_package_file, package: package_on_shard_bar) }

      # Create a package file owned by a particular namespace, and create
      # another package file owned via a nested group.
      let_it_be(:root_group) { create(:group) }
      let_it_be(:subgroup) { create(:group, parent: root_group) }
      let_it_be(:project_in_root_group) { create(:project, group: root_group) }
      let_it_be(:project_in_subgroup) { create(:project, group: subgroup) }
      let_it_be(:package_in_root_group) { create(:conan_package, without_package_files: true, project: project_in_root_group) }
      let_it_be(:package_in_subgroup) { create(:conan_package, without_package_files: true, project: project_in_subgroup) }
      let_it_be(:package_file_in_root_group) { create(:conan_package_file, package: package_in_root_group) }
      let_it_be(:package_file_in_subgroup) { create(:conan_package_file, package: package_in_subgroup) }

      before do
        stub_current_geo_node(secondary)
      end

      context 'without selective sync' do
        let_it_be(:secondary) { create(:geo_node) }

        it 'includes records owned by projects in all shards' do
          expect(subject).to include(package_file_on_shard_foo)
          expect(subject).to include(package_file_on_shard_bar)
        end

        it 'includes records owned by projects in all namespaces' do
          expect(subject).to include(package_file_in_root_group)
          expect(subject).to include(package_file_in_subgroup)
        end
      end

      context 'with selective sync by shard' do
        let_it_be(:secondary) { create(:geo_node, selective_sync_type: 'shards', selective_sync_shards: ['foo']) }

        it 'includes records owned by projects on a selected shard' do
          expect(subject).to include(package_file_on_shard_foo)
        end

        it 'excludes records owned by projects not on a selected shard' do
          expect(subject).not_to include(package_file_on_shard_bar)
        end
      end

      context 'with selective sync by namespace' do
        context 'with sync object storage enabled' do
          let_it_be(:secondary) { create(:geo_node, selective_sync_type: 'namespaces', namespaces: [root_group]) }

          it 'includes records owned by projects on a selected namespace' do
            expect(subject).to include(package_file_in_root_group)
            expect(subject).to include(package_file_in_subgroup)
          end

          it 'excludes records owned by projects not on a selected namespace' do
            expect(subject).not_to include(package_file_on_shard_foo)
            expect(subject).not_to include(package_file_on_shard_bar)
          end
        end

        # The most complex permutation
        context 'with sync object storage disabled' do
          let_it_be(:secondary) { create(:geo_node, selective_sync_type: 'namespaces', namespaces: [root_group], sync_object_storage: false) }

          it 'includes locally stored records owned by projects on a selected namespace' do
            expect(subject).to include(package_file_in_root_group)
            expect(subject).to include(package_file_in_subgroup)
          end

          it 'excludes locally stored records owned by projects not on a selected namespace' do
            expect(subject).not_to include(package_file_on_shard_foo)
            expect(subject).not_to include(package_file_on_shard_bar)
          end

          it 'excludes object stored records owned by projects on a selected namespace' do
            package_file_in_root_group.update_column(:file_store, ::Packages::PackageFileUploader::Store::REMOTE)
            package_file_in_subgroup.update_column(:file_store, ::Packages::PackageFileUploader::Store::REMOTE)

            expect(subject).not_to include(package_file_in_root_group)
            expect(subject).not_to include(package_file_in_subgroup)
          end
        end
      end
    end
  end

  describe '.search' do
    let_it_be(:package_file1) { create(:package_file) }
    let_it_be(:package_file2) { create(:package_file) }

    context 'when search query is empty' do
      it 'returns all records' do
        result = described_class.search('')

        expect(result).to contain_exactly(package_file1, package_file2)
      end
    end

    context 'when search query is not empty' do
      context 'without matches' do
        it 'filters all package files' do
          result = described_class.search('something_that_does_not_exist')

          expect(result).to be_empty
        end
      end

      context 'with matches' do
        context 'with matches by attributes' do
          where(:searchable_attributes) { described_class::EE_SEARCHABLE_ATTRIBUTES }

          before do
            # Use update_column to bypass attribute validations like regex formatting, checksum, etc.
            package_file1.update_column(searchable_attributes, 'any_keyword')
          end

          with_them do
            it 'returns filtered package_files limited to 500 records' do
              expect_any_instance_of(described_class) do |instance|
                expect(instance).to receive(:limit).and_return(500)
              end

              result = described_class.search('any_keyword')

              expect(result).to contain_exactly(package_file1)
            end
          end
        end
      end
    end
  end
end
