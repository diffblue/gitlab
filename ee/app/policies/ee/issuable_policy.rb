# frozen_string_literal: true

module EE
  module IssuablePolicy
    extend ActiveSupport::Concern

    prepended do
      condition(:is_author) do
        @user && @subject.author_id == @user.id
      end

      with_scope :subject
      condition(:timeline_events_available) do
        ::Gitlab::IncidentManagement.timeline_events_available?(@subject.project)
      end

      rule { can?(:read_issue) }.policy do
        enable :read_issuable_metric_image
      end

      rule { can?(:read_issue) & timeline_events_available }.policy do
        enable :read_incident_management_timeline_event
      end

      rule { can?(:read_issue) & can?(:developer_access) & timeline_events_available }.policy do
        enable :admin_incident_management_timeline_event
      end

      rule { can?(:create_issue) & can?(:update_issue) }.policy do
        enable :upload_issuable_metric_image
      end

      rule { is_author | can?(:create_issue) & can?(:update_issue) }.policy do
        enable :destroy_issuable_metric_image
      end

      rule { ~is_project_member }.policy do
        prevent :upload_issuable_metric_image
        prevent :destroy_issuable_metric_image
      end
    end
  end
end
