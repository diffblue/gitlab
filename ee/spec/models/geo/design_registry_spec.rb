# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::DesignRegistry, :geo, feature_category: :geo_replication do
  include ::EE::GeoHelpers
  using RSpec::Parameterized::TableSyntax

  it_behaves_like 'a BulkInsertSafe model', Geo::DesignRegistry do
    let(:valid_items_for_bulk_insertion) do
      build_list(:geo_design_registry, 10, created_at: Time.zone.now) do |registry|
        registry.project = create(:project)
      end
    end

    let(:invalid_items_for_bulk_insertion) { [] } # class does not have any validations defined
  end

  describe 'relationships' do
    it { is_expected.to belong_to(:project) }
  end

  it_behaves_like 'a Geo registry' do
    let(:registry) { create(:geo_design_registry) }
  end

  describe '.find_registry_differences' do
    let_it_be(:secondary) { create(:geo_node) }
    let_it_be(:synced_group) { create(:group) }
    let_it_be(:nested_group) { create(:group, parent: synced_group) }
    let_it_be(:project_1) { create(:project, group: synced_group) }
    let_it_be(:project_2) { create(:project, group: nested_group) }
    let_it_be(:project_3) { create(:project) }
    let_it_be(:project_4) { create(:project) }
    let_it_be(:project_5) { create(:project, :broken_storage) }
    let_it_be(:project_6) { create(:project, :broken_storage) }
    let_it_be(:project_7) { create(:project) }

    before do
      stub_current_geo_node(secondary)
    end

    before_all do
      create(:design, project: project_1)
      create(:design, project: project_2)
      create(:design, project: project_3)
      create(:design, project: project_4)
      create(:design, project: project_5)
      create(:design, project: project_6)
    end

    context 'untracked IDs' do
      before do
        create(:geo_design_registry, project_id: project_1.id)
        create(:geo_design_registry, :sync_failed, project_id: project_3.id)
        create(:geo_design_registry, project_id: project_5.id)
      end

      it 'includes project IDs without an entry on the tracking database' do
        range = Project.minimum(:id)..Project.maximum(:id)

        untracked_ids, _ = described_class.find_registry_differences(range)

        expect(untracked_ids).to match_array([project_2.id, project_4.id, project_6.id])
      end

      it 'excludes projects outside the ID range' do
        untracked_ids, _ = described_class.find_registry_differences(project_4.id..project_6.id)

        expect(untracked_ids).to match_array([project_4.id, project_6.id])
      end

      it 'excludes projects without designs' do
        range = Project.minimum(:id)..Project.maximum(:id)

        untracked_ids, _ = described_class.find_registry_differences(range)

        expect(untracked_ids).not_to include([project_7])
      end

      context 'with selective sync by namespace' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'namespaces', namespaces: [synced_group]) }

        it 'excludes project IDs that are not in selectively synced projects' do
          range = Project.minimum(:id)..Project.maximum(:id)

          untracked_ids, _ = described_class.find_registry_differences(range)

          expect(untracked_ids).to match_array([project_2.id])
        end
      end

      context 'with selective sync by shard' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'shards', selective_sync_shards: ['broken']) }

        it 'excludes project IDs that are not in selectively synced projects' do
          range = Project.minimum(:id)..Project.maximum(:id)

          untracked_ids, _ = described_class.find_registry_differences(range)

          expect(untracked_ids).to match_array([project_6.id])
        end
      end
    end

    context 'unused tracked IDs' do
      context 'with an orphaned registry' do
        let!(:orphaned) { create(:geo_design_registry, project_id: project_1.id) }

        before do
          project_1.delete
        end

        it 'includes tracked IDs that do not exist in the model table' do
          range = project_1.id..project_1.id

          _, unused_tracked_ids = described_class.find_registry_differences(range)

          expect(unused_tracked_ids).to match_array([project_1.id])
        end

        it 'excludes IDs outside the ID range' do
          range = (project_1.id + 1)..Project.maximum(:id)

          _, unused_tracked_ids = described_class.find_registry_differences(range)

          expect(unused_tracked_ids).to be_empty
        end
      end

      context 'with selective sync by namespace' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'namespaces', namespaces: [synced_group]) }

        context 'with a tracked project' do
          context 'excluded from selective sync' do
            let!(:registry_entry) { create(:geo_design_registry, project_id: project_3.id) }

            it 'includes tracked project IDs that exist but are not in a selectively synced project' do
              range = project_3.id..project_3.id

              _, unused_tracked_ids = described_class.find_registry_differences(range)

              expect(unused_tracked_ids).to match_array([project_3.id])
            end
          end

          context 'included in selective sync' do
            let!(:registry_entry) { create(:geo_design_registry, project_id: project_1.id) }

            it 'excludes tracked project IDs that are in selectively synced projects' do
              range = project_1.id..project_1.id

              _, unused_tracked_ids = described_class.find_registry_differences(range)

              expect(unused_tracked_ids).to be_empty
            end
          end
        end
      end

      context 'with selective sync by shard' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'shards', selective_sync_shards: ['broken']) }

        context 'with a tracked project' do
          let!(:registry_entry) { create(:geo_design_registry, project_id: project_1.id) }

          context 'excluded from selective sync' do
            it 'includes tracked project IDs that exist but are not in a selectively synced project' do
              range = project_1.id..project_1.id

              _, unused_tracked_ids = described_class.find_registry_differences(range)

              expect(unused_tracked_ids).to match_array([project_1.id])
            end
          end

          context 'included in selective sync' do
            let!(:registry_entry) { create(:geo_design_registry, project_id: project_5.id) }

            it 'excludes tracked project IDs that are in selectively synced projects' do
              range = project_5.id..project_5.id

              _, unused_tracked_ids = described_class.find_registry_differences(range)

              expect(unused_tracked_ids).to be_empty
            end
          end
        end
      end
    end
  end

  describe '#search' do
    let!(:design_registry) { create(:geo_design_registry) }
    let!(:failed_registry) { create(:geo_design_registry, :sync_failed) }
    let!(:synced_registry) { create(:geo_design_registry, :synced) }

    it 'all the registries' do
      result = described_class.search({})

      expect(result.count).to eq(3)
    end

    it 'finds by state' do
      result = described_class.search({ sync_status: :failed })

      expect(result.count).to eq(1)
      expect(result.first.state).to eq('failed')
    end

    it 'finds by name' do
      project = create(:project, name: 'bla')
      create(:design, project: project)
      create(:geo_design_registry, project: project)

      result = described_class.search({ search: 'bla' })

      expect(result.count).to eq(1)
      expect(result.first.project_id).to eq(project.id)
    end
  end

  describe '#finish_sync!' do
    let(:design_registry) { create(:geo_design_registry, :sync_started) }

    it 'finishes registry record' do
      design_registry.finish_sync!

      expect(design_registry.reload).to have_attributes(
        retry_count: 0,
        retry_at: nil,
        last_sync_failure: nil,
        state: 'synced',
        missing_on_primary: false,
        force_to_redownload: false
      )
    end

    context 'when a design sync was scheduled after the last sync began' do
      before do
        design_registry.update!(
          state: 'pending',
          retry_count: 2,
          retry_at: 1.hour.ago,
          force_to_redownload: true,
          last_sync_failure: 'error',
          missing_on_primary: true
        )

        design_registry.finish_sync!
      end

      it 'does not reset state' do
        expect(design_registry.reload.state).to eq 'pending'
      end

      it 'resets the other sync state fields' do
        expect(design_registry.reload).to have_attributes(
          retry_count: 0,
          retry_at: nil,
          force_to_redownload: false,
          last_sync_failure: nil,
          missing_on_primary: false
        )
      end
    end
  end

  describe '#should_be_redownloaded?' do
    where(:force_to_redownload, :retry_count, :expected) do
      false | nil | false
      false | 0   | false
      false | 1   | false
      false | 10  | false
      false | 11  | true
      false | 12  | false
      false | 13  | true
      false | 14  | false
      false | 101 | true
      false | 102 | false
      true  | nil | true
      true  | 0   | true
      true  | 11  | true
    end

    with_them do
      it "returns the expected boolean" do
        registry = build(:geo_design_registry, retry_count: retry_count, force_to_redownload: force_to_redownload)

        expect(registry.should_be_redownloaded?).to eq(expected)
      end
    end
  end
end
