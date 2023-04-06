# frozen_string_literal: true

module EE
  module MembersHelper
    def members_page?
      current_path?('groups/group_members#index') ||
        current_path?('projects/project_members#index')
    end

    private

    def member_header_manage_namespace_members_text(namespace)
      manage_text = _(
        'To manage seats for all members associated with this group and its subgroups and projects, ' \
        'visit the %{link_start}usage quotas page%{link_end}.'
      ).html_safe % {
        link_start: "<a href='#{group_usage_quotas_path(namespace)}'>".html_safe,
        link_end: '</a>'.html_safe
      }

      "<br />".html_safe + manage_text
    end
  end
end
