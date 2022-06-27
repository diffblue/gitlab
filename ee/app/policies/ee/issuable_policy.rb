# frozen_string_literal: true

module EE
  module IssuablePolicy
    extend ActiveSupport::Concern

    prepended do
      condition(:is_author) do
        @user && @subject.author_id == @user.id
      end

      with_scope :subject
      condition(:issuable_resource_links_available) do
        @subject.issuable_resource_links_available?
      end

      rule { can?(:read_issue) }.policy do
        enable :read_issuable_metric_image
      end

      rule { can?(:create_issue) & can?(:update_issue) }.policy do
        enable :upload_issuable_metric_image
      end

      rule { is_author | can?(:create_issue) & can?(:update_issue) }.policy do
        enable :update_issuable_metric_image
        enable :destroy_issuable_metric_image
      end

      rule { ~is_project_member }.policy do
        prevent :upload_issuable_metric_image
        prevent :update_issuable_metric_image
        prevent :destroy_issuable_metric_image
      end

      rule { can?(:read_issue) & can?(:reporter_access) & issuable_resource_links_available }.policy do
        enable :admin_issuable_resource_link
        enable :read_issuable_resource_link
      end
    end
  end
end
