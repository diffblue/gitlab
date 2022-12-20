# frozen_string_literal: true

module EE
  module NotesHelper
    extend ::Gitlab::Utils::Override

    override :notes_url
    def notes_url(params = {})
      return group_epic_notes_path(@epic.group, @epic) if @epic.is_a?(Epic)
      return project_security_vulnerability_notes_path(@vulnerability.project, @vulnerability) if @vulnerability.is_a?(Vulnerability)

      super
    end

    override :discussions_path
    def discussions_path(issuable, **params)
      return discussions_group_epic_path(issuable.group, issuable, params.merge(format: :json)) if issuable.is_a?(Epic)
      return discussions_project_security_vulnerability_path(issuable.project, issuable, params.merge(format: :json)) if issuable.is_a?(Vulnerability)

      super
    end

    def description_diff_path(issuable, version_id)
      url_helper = ::Gitlab::Routing.url_helpers

      case issuable
      when Issue
        url_helper.description_diff_project_issue_path(issuable.project, issuable, version_id)
      when MergeRequest
        url_helper.description_diff_project_merge_request_path(issuable.project, issuable, version_id)
      when Epic
        url_helper.description_diff_group_epic_path(issuable.group, issuable, version_id)
      end
    end

    def delete_description_version_path(issuable, version_id)
      url_helper = ::Gitlab::Routing.url_helpers

      case issuable
      when Issue
        url_helper.delete_description_version_project_issue_path(issuable.project, issuable, version_id)
      when MergeRequest
        url_helper.delete_description_version_project_merge_request_path(issuable.project, issuable, version_id)
      when Epic
        url_helper.delete_description_version_group_epic_path(issuable.group, issuable, version_id)
      end
    end
  end
end
