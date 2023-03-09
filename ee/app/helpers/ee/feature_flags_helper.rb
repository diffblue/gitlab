# frozen_string_literal: true

module EE
  module FeatureFlagsHelper
    extend ::Gitlab::Utils::Override

    override :edit_feature_flag_data
    def edit_feature_flag_data
      super.merge(
        feature_flag_issues_endpoint: feature_flag_issues_links_endpoint(@project, @feature_flag, current_user),
        search_path: feature_flags_search_path(@project, @feature_flag, current_user)
      )
    end

    private

    def feature_flag_issues_links_endpoint(project, feature_flag, user)
      return '' unless can?(user, :admin_feature_flags_issue_links, project)

      project_feature_flag_issues_path(project, feature_flag)
    end

    def feature_flags_search_path(project, feature_flag, user)
      return '' unless project.licensed_feature_available?(:feature_flags_code_references, user)

      search_path(project_id: project.id, search: feature_flag.name, scope: :blobs)
    end
  end
end
