# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::ProjectRegistryFinder, :geo, feature_category: :geo_replication do
  let_it_be(:project_1) { create(:project) }
  let_it_be(:project_2) { create(:project) }
  let_it_be(:project_3) { create(:project) }
  let_it_be(:project_4) { create(:project) }
  let_it_be(:project_5) { create(:project) }
  let_it_be(:project_6) { create(:project) }

  let_it_be(:registry_project_1) { create(:geo_project_registry, :synced, project_id: project_1.id) }
  let_it_be(:registry_project_2) { create(:geo_project_registry, :sync_failed, project_id: project_2.id) }
  let_it_be(:registry_project_3) { create(:geo_project_registry, project_id: project_3.id) }
  let_it_be(:registry_project_4) { create(:geo_project_registry, :repository_dirty, project_id: project_4.id, last_repository_synced_at: 2.days.ago) }
  let_it_be(:registry_project_5) { create(:geo_project_registry, :wiki_dirty, project_id: project_5.id, last_repository_synced_at: 5.days.ago) }
  let_it_be(:registry_project_6) { create(:geo_project_registry, project_id: project_6.id) }

  describe '#find_registries_never_attempted_sync' do
    it 'returns registries for projects that have never have an attempt to sync' do
      registries = subject.find_registries_never_attempted_sync(batch_size: 10)

      expect(registries).to match_ids(registry_project_3, registry_project_6)
    end

    it 'excludes except_ids' do
      registries = subject.find_registries_never_attempted_sync(batch_size: 10, except_ids: [project_3.id])

      expect(registries).to match_ids(registry_project_6)
    end
  end

  describe '#find_registries_needs_sync_again' do
    context 'with geo_project_wiki_repository_replication feature flag disabled' do
      before do
        stub_feature_flags(geo_project_wiki_repository_replication: false)
      end

      it 'returns registries for dirty projects and/or wiki or that have failed to sync' do
        registries = subject.find_registries_needs_sync_again(batch_size: 10)

        expect(registries).to match_ids(registry_project_2, registry_project_3, registry_project_4, registry_project_5, registry_project_6)
      end

      it 'excludes except_ids' do
        registries = subject.find_registries_needs_sync_again(batch_size: 10, except_ids: [project_4.id, project_5.id, project_6.id])

        expect(registries).to match_ids(registry_project_2, registry_project_3)
      end
    end

    context 'with geo_project_wiki_repository_replication feature flag enabled' do
      before do
        stub_feature_flags(geo_project_wiki_repository_replication: true)
      end

      it 'returns registries for dirty projects or that have failed to sync' do
        registries = subject.find_registries_needs_sync_again(batch_size: 10)

        expect(registries).to match_ids(registry_project_2, registry_project_3, registry_project_4, registry_project_6)
      end

      it 'excludes except_ids' do
        registries = subject.find_registries_needs_sync_again(batch_size: 10, except_ids: [project_4.id, project_5.id, project_6.id])

        expect(registries).to match_ids(registry_project_2, registry_project_3)
      end
    end
  end

  describe '#find_project_ids_pending_verification' do
    context 'with geo_project_wiki_repository_replication feature flag disabled' do
      before do
        stub_feature_flags(geo_project_wiki_repository_replication: false)
      end

      it 'returns project IDs where repository and/or wiki is pending verification' do
        project_ids = subject.find_project_ids_pending_verification(batch_size: 10)

        expect(project_ids).to match_array([project_1.id, project_4.id, project_5.id])
      end

      it 'excludes registries where repository and wiki is missing on primary' do
        registry_project_7 = create(:geo_project_registry, :synced, repository_missing_on_primary: true)
        registry_project_8 = create(:geo_project_registry, :synced, wiki_missing_on_primary: true)
        create(:geo_project_registry, :synced, repository_missing_on_primary: true, wiki_missing_on_primary: true)

        project_ids = subject.find_project_ids_pending_verification(batch_size: 10)

        expect(project_ids).to match_array([project_1.id, project_4.id, project_5.id, registry_project_7.project_id, registry_project_8.project_id])
      end

      it 'excludes registries where repository and wiki has not been verified on primary' do
        registry_project_7 = create(:geo_project_registry, :synced, primary_repository_checksummed: false)
        registry_project_8 = create(:geo_project_registry, :synced, primary_wiki_checksummed: false)
        create(:geo_project_registry, :synced, primary_repository_checksummed: false, primary_wiki_checksummed: false)

        project_ids = subject.find_project_ids_pending_verification(batch_size: 10)

        expect(project_ids).to match_array([project_1.id, project_4.id, project_5.id, registry_project_7.project_id, registry_project_8.project_id])
      end

      it 'excludes except_ids' do
        project_ids = subject.find_project_ids_pending_verification(batch_size: 10, except_ids: [project_5.id])

        expect(project_ids).to match_array([project_1.id, project_4.id])
      end
    end

    context 'with geo_project_wiki_repository_replication feature flag enabled' do
      before do
        stub_feature_flags(geo_project_wiki_repository_replication: true)
      end

      it 'returns project IDs where repository is pending verification' do
        project_ids = subject.find_project_ids_pending_verification(batch_size: 10)

        expect(project_ids).to match_array([project_1.id, project_5.id])
      end

      it 'excludes registries where repository is missing on primary' do
        create(:geo_project_registry, :synced, repository_missing_on_primary: true)
        registry_project_8 = create(:geo_project_registry, :synced, wiki_missing_on_primary: true)
        create(:geo_project_registry, :synced, repository_missing_on_primary: true, wiki_missing_on_primary: true)

        project_ids = subject.find_project_ids_pending_verification(batch_size: 10)

        expect(project_ids).to match_array([project_1.id, project_5.id, registry_project_8.project_id])
      end

      it 'excludes registries where repository has not been verified on primary' do
        create(:geo_project_registry, :synced, primary_repository_checksummed: false)
        registry_project_8 = create(:geo_project_registry, :synced, primary_wiki_checksummed: false)
        create(:geo_project_registry, :synced, primary_repository_checksummed: false, primary_wiki_checksummed: false)

        project_ids = subject.find_project_ids_pending_verification(batch_size: 10)

        expect(project_ids).to match_array([project_1.id, project_5.id, registry_project_8.project_id])
      end

      it 'excludes except_ids' do
        project_ids = subject.find_project_ids_pending_verification(batch_size: 10, except_ids: [project_5.id])

        expect(project_ids).to match_array([project_1.id])
      end
    end
  end
end
