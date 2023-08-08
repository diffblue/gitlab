# frozen_string_literal: true

module EE
  module IssuablesHelper
    extend ::Gitlab::Utils::Override

    override :issuable_sidebar_options
    def issuable_sidebar_options(sidebar_data)
      super.merge(
        weightOptions: ::Issue.weight_options,
        weightNoneValue: ::Issue::WEIGHT_NONE
      )
    end

    override :issuable_initial_data
    def issuable_initial_data(issuable)
      data = super.merge(
        canAdmin: can?(current_user, :"admin_#{issuable.to_ability_name}", issuable),
        hasIssueWeightsFeature: issuable.project&.licensed_feature_available?(:issue_weights),
        hasIterationsFeature: issuable.project&.licensed_feature_available?(:iterations),
        canAdminRelation: can?(current_user, :"admin_#{issuable.to_ability_name}_relation", issuable)
      )

      if parent.is_a?(Group)
        data[:confidential] = issuable.confidential
        data[:epicLinksEndpoint] = group_epic_links_path(parent, issuable)
        data[:epicsWebUrl] = group_epics_path(parent)
        data[:fullPath] = parent.full_path
        data[:issueLinksEndpoint] = group_epic_issues_path(parent, issuable)
        data[:issuesWebUrl] = issues_group_path(parent)
        data[:projectsEndpoint] = expose_path(api_v4_groups_projects_path(id: parent.id))
      end

      data
    end

    override :issue_only_initial_data
    def issue_only_initial_data(issuable)
      return {} unless issuable.is_a?(Issue)

      data = super.merge(
        publishedIncidentUrl: ::Gitlab::StatusPage::Storage.details_url(issuable),
        slaFeatureAvailable: issuable.sla_available?.to_s,
        uploadMetricsFeatureAvailable: issuable.metric_images_available?.to_s,
        projectId: issuable.project_id
      )

      data.tap do |d|
        if issuable.promoted? && can?(current_user, :read_epic, issuable.promoted_to_epic)
          d[:promotedToEpicUrl] =
            url_for([issuable.promoted_to_epic.group, issuable.promoted_to_epic, { only_path: false }])
        end
      end
    end
  end
end
