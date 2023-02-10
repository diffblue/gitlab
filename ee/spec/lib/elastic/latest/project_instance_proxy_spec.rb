# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Elastic::Latest::ProjectInstanceProxy, feature_category: :global_search do
  let_it_be(:project) { create(:project) }

  subject { described_class.new(project) }

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

      Elastic::Latest::ProjectInstanceProxy::TRACKED_FEATURE_SETTINGS.each do |feature|
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
