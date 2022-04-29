# frozen_string_literal: true

module Projects
  class IssueFeatureFlagsController < Projects::ApplicationController
    include IssuableLinks

    before_action :authorize_admin_feature_flags_issue_links!

    feature_category :feature_flags
    urgency :low, [:index, :show]

    private

    def list_service
      ::IssueFeatureFlags::ListService.new(issue, current_user)
    end

    def link
      @link ||= ::FeatureFlagIssue.find(params[:id])
    end

    def issue
      project.issues.find_by_iid(params[:issue_id])
    end
  end
end
