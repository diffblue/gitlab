# frozen_string_literal: true

module EpicsHelper
  def epic_initial_data(epic)
    issuable_initial_data(epic).merge(canCreate: can?(current_user, :create_epic, epic.group))
  end

  def epic_show_app_data(epic)
    EpicPresenter.new(epic, current_user: current_user).show_data(author_icon: avatar_icon_for_user(epic.author), base_data: epic_initial_data(epic))
  end

  def epic_new_app_data(group)
    {
      group_path: group.full_path,
      group_epics_path: group_epics_path(group),
      labels_fetch_path: group_labels_path(group, format: :json, only_group_labels: true, include_ancestor_groups: true),
      labels_manage_path: group_labels_path(group),
      markdown_preview_path: preview_markdown_path(group),
      markdown_docs_path: help_page_path('user/markdown')
    }
  end

  def award_emoji_epics_api_path(epic)
    api_v4_groups_epics_award_emoji_path(id: epic.group.id, epic_iid: epic.iid)
  end
end
