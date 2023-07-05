# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Elastic::Latest::ProjectInstanceProxy, feature_category: :global_search do
  include ElasticsearchHelpers
  let_it_be(:project) { create(:project) }

  subject { described_class.new(project) }

  describe 'when migrate_projects_to_separate_index migration is not completed' do
    before do
      stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
      set_elasticsearch_migration_to(:migrate_projects_to_separate_index, including: false)
      ensure_elasticsearch_index! # ensure objects are indexed
    end

    describe '#as_indexed_json' do
      it 'serializes project as hash' do
        result = subject.as_indexed_json.with_indifferent_access

        expect(result).to include(
          id: project.id,
          name: project.name,
          path: project.path,
          description: project.description,
          namespace_id: project.namespace_id,
          created_at: project.created_at,
          updated_at: project.updated_at,
          archived: project.archived,
          visibility_level: project.visibility_level,
          last_activity_at: project.last_activity_at,
          name_with_namespace: project.name_with_namespace,
          path_with_namespace: project.path_with_namespace)

        described_class::TRACKED_FEATURE_SETTINGS.each do |feature|
          expect(result).to include(feature => project.project_feature.public_send(feature)) # rubocop:disable GitlabSecurity/PublicSend
        end
      end

      context 'when project_feature is null' do
        before do
          allow(project).to receive(:project_feature).and_return(nil)
        end

        it 'sets all tracked feature access levels to PRIVATE' do
          result = subject.as_indexed_json.with_indifferent_access

          Elastic::Latest::ProjectInstanceProxy::TRACKED_FEATURE_SETTINGS.each do |feature|
            expect(result).to include(feature => ProjectFeature::PRIVATE) # rubocop:disable GitlabSecurity/PublicSend
          end
        end
      end
    end
  end

  describe 'when migrate_projects_to_separate_index migration is completed' do
    before do
      stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
      set_elasticsearch_migration_to(:migrate_projects_to_separate_index, including: true)
      ensure_elasticsearch_index! # ensure objects are indexed
    end

    describe '#as_indexed_json' do
      it 'serializes project as hash' do
        result = subject.as_indexed_json.with_indifferent_access

        expect(result).to include(
          id: project.id,
          name: project.name,
          path: project.path,
          description: project.description,
          namespace_id: project.namespace_id,
          created_at: project.created_at,
          updated_at: project.updated_at,
          archived: project.archived,
          last_activity_at: project.last_activity_at,
          name_with_namespace: project.name_with_namespace,
          path_with_namespace: project.path_with_namespace,
          traversal_ids: project.elastic_namespace_ancestry,
          type: 'project',
          visibility_level: project.visibility_level,
          schema_version: 23_06,
          ci_catalog: project.catalog_resource.present?
        )
      end

      it 'contains the expected mappings' do
        result = subject.as_indexed_json.with_indifferent_access.keys
        project_proxy = Elastic::Latest::ApplicationClassProxy.new(Project, use_separate_indices: true)
        # readme_content is not populated by as_indexed_json
        expected_keys = project_proxy.mappings.to_hash[:properties].keys.map(&:to_s) - ['readme_content']

        expect(result).to match_array(expected_keys)
      end
    end
  end
end
