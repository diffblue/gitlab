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
        canAdmin: can?(current_user, :"admin_#{issuable.to_ability_name}", issuable)
      )

      if parent.is_a?(Group)
        data[:issueLinksEndpoint] = group_epic_issues_path(parent, issuable)
        data[:epicLinksEndpoint] = group_epic_links_path(parent, issuable)
        data[:fullPath] = parent.full_path
        data[:projectsEndpoint] = expose_path(api_v4_groups_projects_path(id: parent.id))
        data[:confidential] = issuable.confidential
      end

      data
    end

    override :issue_only_initial_data
    def issue_only_initial_data(issuable)
      return {} unless issuable.is_a?(Issue)

      super.merge(
        publishedIncidentUrl: ::Gitlab::StatusPage::Storage.details_url(issuable),
        slaFeatureAvailable: issuable.sla_available?.to_s,
        uploadMetricsFeatureAvailable: issuable.metric_images_available?.to_s,
        projectId: issuable.project_id
      )
    end

    override :issuable_meta_author_slot
    def issuable_meta_author_slot(author, css_class: nil)
      gitlab_team_member_badge(author, css_class: css_class)
    end

    def gitlab_team_member_badge(author, css_class: nil)
      return unless author.gitlab_employee? && ::Feature.enabled?(:gitlab_employee_badge)

      default_css_class = 'd-inline-block align-middle'
      gitlab_team_member = _('GitLab Team Member')

      content_tag(
        :span,
        class: css_class ? "#{default_css_class} #{css_class}" : default_css_class,
        data: { toggle: 'tooltip', title: gitlab_team_member, container: 'body' },
        role: 'img',
        aria: { label: gitlab_team_member }
      ) do
        sprite_icon(
          'tanuki-verified',
          size: 16,
          css_class: 'gl-text-purple-600 d-block'
        )
      end
    end
  end
end
