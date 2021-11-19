# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::JobArtifactRegistry, :geo, type: :model do
  include EE::GeoHelpers

  let_it_be(:registry) { create(:geo_job_artifact_registry) }

  specify 'factory is valid' do
    expect(registry).to be_valid
  end

  include_examples 'a Geo framework registry'
  include_examples 'a Geo verifiable registry'

  context "deprecated registry functionality" do
    before do
      stub_feature_flags(geo_job_artifact_replication: false)
    end

    it_behaves_like 'a BulkInsertSafe model', Geo::JobArtifactRegistry do
      let(:valid_items_for_bulk_insertion) { build_list(:geo_job_artifact_registry, 10) }
      let(:invalid_items_for_bulk_insertion) { [] } # class does not have any validations defined
    end

    describe '.insert_for_model_ids' do
      it 'returns an array with the primary key values for all inserted records' do
        ids = described_class.insert_for_model_ids([1])

        expect(ids).to contain_exactly(a_kind_of(Integer))
      end

      it 'defaults success column to false for all inserted records' do
        ids = described_class.insert_for_model_ids([1])

        expect(described_class.where(id: ids).pluck(:success)).to eq([false])
      end
    end

    describe '.find_registry_differences' do
      let_it_be(:secondary) { create(:geo_node) }

      before do
        stub_current_geo_node(secondary)
        stub_artifacts_object_storage
      end

      let_it_be(:synced_group) { create(:group) }
      let_it_be(:nested_group_1) { create(:group, parent: synced_group) }
      let_it_be(:synced_project) { create(:project, group: synced_group) }
      let_it_be(:synced_project_in_nested_group) { create(:project, group: nested_group_1) }
      let_it_be(:unsynced_project) { create(:project) }
      let_it_be(:project_broken_storage) { create(:project, :broken_storage) }

      let_it_be(:ci_job_artifact_1) { create(:ci_job_artifact, project: synced_project) }
      let_it_be(:ci_job_artifact_2) { create(:ci_job_artifact, project: synced_project_in_nested_group) }
      let_it_be(:ci_job_artifact_3) { create(:ci_job_artifact, project: synced_project_in_nested_group) }
      let_it_be(:ci_job_artifact_4) { create(:ci_job_artifact, project: unsynced_project) }
      let_it_be(:ci_job_artifact_5) { create(:ci_job_artifact, project: project_broken_storage) }
      let!(:ci_job_artifact_remote_1) { create(:ci_job_artifact, :remote_store) }
      let!(:ci_job_artifact_remote_2) { create(:ci_job_artifact, :remote_store) }
      let!(:ci_job_artifact_remote_3) { create(:ci_job_artifact, :remote_store) }

      # Expired job artifacts used to be excluded, but are now included
      let_it_be(:ci_job_artifact_6) { create(:ci_job_artifact, :expired, project: synced_project) }

      context 'untracked IDs' do
        before do
          create(:geo_job_artifact_registry_legacy, artifact_id: ci_job_artifact_1.id)
          create(:geo_job_artifact_registry_legacy, :failed, artifact_id: ci_job_artifact_3.id)
          create(:geo_job_artifact_registry_legacy, artifact_id: ci_job_artifact_4.id)
        end

        it 'includes job artifact IDs without an entry on the tracking database' do
          untracked_ids, _ = described_class.find_registry_differences(Ci::JobArtifact.first.id..Ci::JobArtifact.last.id)

          expect(untracked_ids).to match_array(
            [ci_job_artifact_2.id, ci_job_artifact_5.id, ci_job_artifact_remote_1.id,
             ci_job_artifact_remote_2.id, ci_job_artifact_remote_3.id,
             ci_job_artifact_6.id])
        end

        it 'excludes job artifacts outside the ID range' do
          untracked_ids, _ = described_class.find_registry_differences(ci_job_artifact_3.id..ci_job_artifact_remote_2.id)

          expect(untracked_ids).to match_array(
            [ci_job_artifact_5.id, ci_job_artifact_remote_1.id,
             ci_job_artifact_remote_2.id, ci_job_artifact_6.id])
        end

        context 'with selective sync by namespace' do
          let(:secondary) { create(:geo_node, selective_sync_type: 'namespaces', namespaces: [synced_group]) }

          it 'excludes job artifact IDs that are not in selectively synced projects' do
            untracked_ids, _ = described_class.find_registry_differences(Ci::JobArtifact.first.id..Ci::JobArtifact.last.id)

            expect(untracked_ids).to match_array([ci_job_artifact_2.id, ci_job_artifact_6.id])
          end
        end

        context 'with selective sync by shard' do
          let(:secondary) { create(:geo_node, selective_sync_type: 'shards', selective_sync_shards: ['broken']) }

          it 'excludes job artifact IDs that are not in selectively synced projects' do
            untracked_ids, _ = described_class.find_registry_differences(Ci::JobArtifact.first.id..Ci::JobArtifact.last.id)

            expect(untracked_ids).to match_array([ci_job_artifact_5.id])
          end
        end

        context 'with object storage sync disabled' do
          let(:secondary) { create(:geo_node, :local_storage_only) }

          it 'excludes job artifacts in object storage' do
            untracked_ids, _ = described_class.find_registry_differences(Ci::JobArtifact.first.id..Ci::JobArtifact.last.id)

            expect(untracked_ids).to match_array([ci_job_artifact_2.id, ci_job_artifact_5.id, ci_job_artifact_6.id])
          end
        end
      end

      context 'unused tracked IDs' do
        context 'with an orphaned registry' do
          let!(:orphaned) { create(:geo_job_artifact_registry_legacy, artifact_id: non_existing_record_id) }

          it 'includes tracked IDs that do not exist in the model table' do
            range = non_existing_record_id..non_existing_record_id

            _, unused_tracked_ids = described_class.find_registry_differences(range)

            expect(unused_tracked_ids).to match_array([non_existing_record_id])
          end

          it 'excludes IDs outside the ID range' do
            range = 1..1000

            _, unused_tracked_ids = described_class.find_registry_differences(range)

            expect(unused_tracked_ids).to be_empty
          end
        end

        context 'with selective sync by namespace' do
          let(:secondary) { create(:geo_node, selective_sync_type: 'namespaces', namespaces: [synced_group]) }

          context 'with a tracked job artifact' do
            let!(:registry_entry) { create(:geo_job_artifact_registry_legacy, artifact_id: ci_job_artifact_1.id) }
            let(:range) { ci_job_artifact_1.id..ci_job_artifact_4.id }

            context 'excluded from selective sync' do
              it 'includes tracked job artifact IDs that exist but are not in a selectively synced project' do
                create(:geo_job_artifact_registry_legacy, artifact_id: ci_job_artifact_4.id)

                _, unused_tracked_ids = described_class.find_registry_differences(range)

                expect(unused_tracked_ids).to match_array([ci_job_artifact_4.id])
              end
            end

            context 'included in selective sync' do
              it 'excludes tracked job artifact IDs that are in selectively synced projects' do
                _, unused_tracked_ids = described_class.find_registry_differences(range)

                expect(unused_tracked_ids).to be_empty
              end
            end
          end
        end

        context 'with selective sync by shard' do
          let(:secondary) { create(:geo_node, selective_sync_type: 'shards', selective_sync_shards: ['broken']) }

          context 'with a tracked job artifact' do
            let!(:registry_entry) { create(:geo_job_artifact_registry_legacy, artifact_id: ci_job_artifact_5.id) }
            let(:range) { ci_job_artifact_1.id..ci_job_artifact_5.id }

            context 'excluded from selective sync' do
              it 'includes tracked job artifact IDs that exist but are not in a selectively synced shard' do
                create(:geo_job_artifact_registry_legacy, artifact_id: ci_job_artifact_1.id)

                _, unused_tracked_ids = described_class.find_registry_differences(range)

                expect(unused_tracked_ids).to match_array([ci_job_artifact_1.id])
              end
            end

            context 'included in selective sync' do
              it 'excludes tracked job artifact IDs that are in selectively synced shards' do
                _, unused_tracked_ids = described_class.find_registry_differences(range)

                expect(unused_tracked_ids).to be_empty
              end
            end
          end
        end

        context 'with object storage sync disabled' do
          let(:secondary) { create(:geo_node, :local_storage_only) }

          context 'with a tracked job artifact' do
            context 'in object storage' do
              it 'includes tracked job artifact IDs that are in object storage' do
                create(:geo_job_artifact_registry_legacy, artifact_id: ci_job_artifact_remote_1.id)
                range = ci_job_artifact_remote_1.id..ci_job_artifact_remote_1.id

                _, unused_tracked_ids = described_class.find_registry_differences(range)

                expect(unused_tracked_ids).to match_array([ci_job_artifact_remote_1.id])
              end
            end

            context 'not in object storage' do
              it 'excludes tracked job artifact IDs that are not in object storage' do
                create(:geo_job_artifact_registry_legacy, artifact_id: ci_job_artifact_1.id)
                range = ci_job_artifact_1.id..ci_job_artifact_1.id

                _, unused_tracked_ids = described_class.find_registry_differences(range)

                expect(unused_tracked_ids).to be_empty
              end
            end
          end
        end
      end
    end
  end
end
