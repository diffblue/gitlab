# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::ContainerRepositoryRegistry, :geo, feature_category: :geo_replication do
  include ::EE::GeoHelpers

  it_behaves_like 'a BulkInsertSafe model', Geo::ContainerRepositoryRegistry do
    let(:valid_items_for_bulk_insertion) { build_list(:geo_container_repository_registry, 10, :with_repository_id, created_at: Time.zone.now) }
    let(:invalid_items_for_bulk_insertion) { [] } # class does not have any validations defined
  end

  describe 'relationships' do
    it { is_expected.to belong_to(:container_repository) }
  end

  describe '#state' do
    using RSpec::Parameterized::TableSyntax

    let(:registry) { create(:geo_container_repository_registry) }

    where(:state, :state_method) do
      '0' | 'pending?'
      '1' | 'started?'
      '2' | 'synced?'
      '3' | 'failed?'
      'pending' | 'pending?'
      'started' | 'started?'
      'synced' | 'synced?'
      'failed' | 'failed?'
    end

    with_them do
      it do
        registry.update_attribute(:state, state)

        expect(registry.public_send(state_method)).to be_truthy
      end
    end
  end

  describe '.find_registry_differences' do
    let_it_be(:secondary) { create(:geo_node) }
    let_it_be(:synced_group) { create(:group) }
    let_it_be(:nested_group) { create(:group, parent: synced_group) }
    let_it_be(:project_synced_group) { create(:project, group: synced_group) }
    let_it_be(:project_nested_group) { create(:project, group: nested_group) }
    let_it_be(:project_broken_storage) { create(:project, :broken_storage) }
    let_it_be(:container_repository_1) { create(:container_repository, project: project_synced_group) }
    let_it_be(:container_repository_2) { create(:container_repository, project: project_nested_group) }
    let_it_be(:container_repository_3) { create(:container_repository) }
    let_it_be(:container_repository_4) { create(:container_repository) }
    let_it_be(:container_repository_5) { create(:container_repository, project: project_broken_storage) }
    let_it_be(:container_repository_6) { create(:container_repository, project: project_broken_storage) }

    before do
      stub_current_geo_node(secondary)
      stub_registry_replication_config(enabled: true)
    end

    context 'untracked IDs' do
      before do
        create(:geo_container_repository_registry, container_repository_id: container_repository_1.id)
        create(:geo_container_repository_registry, :failed, container_repository_id: container_repository_3.id)
        create(:geo_container_repository_registry, container_repository_id: container_repository_5.id)
      end

      it 'includes container registries IDs without an entry on the tracking database' do
        range = ContainerRepository.minimum(:id)..ContainerRepository.maximum(:id)

        untracked_ids, _ = described_class.find_registry_differences(range)

        expect(untracked_ids).to match_array([container_repository_2.id, container_repository_4.id, container_repository_6.id])
      end

      it 'excludes container registries outside the ID range' do
        untracked_ids, _ = described_class.find_registry_differences(container_repository_4.id..container_repository_6.id)

        expect(untracked_ids).to match_array([container_repository_4.id, container_repository_6.id])
      end

      context 'with selective sync by namespace' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'namespaces', namespaces: [synced_group]) }

        it 'excludes container_registry IDs that projects are not in the selected namespaces' do
          range = ContainerRepository.minimum(:id)..ContainerRepository.maximum(:id)

          untracked_ids, _ = described_class.find_registry_differences(range)

          expect(untracked_ids).to match_array([container_repository_2.id])
        end
      end

      context 'with selective sync by shard' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'shards', selective_sync_shards: ['broken']) }

        it 'excludes container_registry IDs that projects are not in the selected shards' do
          range = ContainerRepository.minimum(:id)..ContainerRepository.maximum(:id)

          untracked_ids, _ = described_class.find_registry_differences(range)

          expect(untracked_ids).to match_array([container_repository_6.id])
        end
      end
    end

    context 'unused tracked IDs' do
      context 'with an orphaned registry' do
        let!(:orphaned) { create(:geo_container_repository_registry, container_repository_id: container_repository_1.id) }

        before do
          container_repository_1.delete
        end

        it 'includes tracked IDs that do not exist in the model table' do
          range = container_repository_1.id..container_repository_1.id

          _, unused_tracked_ids = described_class.find_registry_differences(range)

          expect(unused_tracked_ids).to match_array([container_repository_1.id])
        end

        it 'excludes IDs outside the ID range' do
          range = (container_repository_1.id + 1)..ContainerRepository.maximum(:id)

          _, unused_tracked_ids = described_class.find_registry_differences(range)

          expect(unused_tracked_ids).to be_empty
        end
      end

      context 'with selective sync by namespace' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'namespaces', namespaces: [synced_group]) }

        context 'with a tracked container_registry' do
          context 'excluded from selective sync' do
            let!(:registry_entry) { create(:geo_container_repository_registry, container_repository_id: container_repository_3.id) }

            it 'includes tracked container_registry IDs that exist but are not in a selectively synced project' do
              range = container_repository_3.id..container_repository_3.id

              _, unused_tracked_ids = described_class.find_registry_differences(range)

              expect(unused_tracked_ids).to match_array([container_repository_3.id])
            end
          end

          context 'included in selective sync' do
            let!(:registry_entry) { create(:geo_container_repository_registry, container_repository_id: container_repository_1.id) }

            it 'excludes tracked container_registry IDs that are in selectively synced projects' do
              range = container_repository_1.id..container_repository_1.id

              _, unused_tracked_ids = described_class.find_registry_differences(range)

              expect(unused_tracked_ids).to be_empty
            end
          end
        end
      end

      context 'with selective sync by shard' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'shards', selective_sync_shards: ['broken']) }

        context 'with a tracked container_registry' do
          let!(:registry_entry) { create(:geo_container_repository_registry, container_repository_id: container_repository_1.id) }

          context 'excluded from selective sync' do
            it 'includes tracked container_registry IDs that exist but are not in a selectively synced project' do
              range = container_repository_1.id..container_repository_1.id

              _, unused_tracked_ids = described_class.find_registry_differences(range)

              expect(unused_tracked_ids).to match_array([container_repository_1.id])
            end
          end

          context 'included in selective sync' do
            let!(:registry_entry) { create(:geo_container_repository_registry, container_repository_id: container_repository_5.id) }

            it 'excludes tracked container_registry IDs that are in selectively synced projects' do
              range = container_repository_5.id..container_repository_5.id

              _, unused_tracked_ids = described_class.find_registry_differences(range)

              expect(unused_tracked_ids).to be_empty
            end
          end
        end
      end
    end
  end

  describe '.replication_enabled?' do
    it 'returns true when registry replication is enabled' do
      stub_geo_setting(registry_replication: { enabled: true })

      expect(Geo::ContainerRepositoryRegistry.replication_enabled?).to be_truthy
    end

    it 'returns false when registry replication is disabled' do
      stub_geo_setting(registry_replication: { enabled: false })

      expect(Geo::ContainerRepositoryRegistry.replication_enabled?).to be_falsey
    end
  end

  describe '.fail_sync_timeouts' do
    it 'marks started records as failed if they are expired' do
      record1 = create(:geo_container_repository_registry, :started, last_synced_at: 9.hours.ago)
      record2 = create(:geo_container_repository_registry, :started, last_synced_at: 1.hour.ago) # not yet expired

      described_class.fail_sync_timeouts

      expect(record1.reload.failed?).to be_truthy
      expect(record2.reload.started?).to be_truthy
    end
  end
end

RSpec.describe Geo::ContainerRepositoryRegistry, :geo, type: :model, feature_category: :geo_replication do
  let(:registry) { create(:geo_container_repository_registry) }

  specify 'factory is valid' do
    expect(registry).to be_valid
  end

  include_examples 'a Geo framework registry'

  include_examples 'a Geo searchable registry'

  include_examples 'a Geo verifiable registry'
end
