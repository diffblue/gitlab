# frozen_string_literal: true

module EE
  module Notify
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    # We need to put includes in prepended block due to the magical
    # interaction between ActiveSupport::Concern and ActionMailer::Base
    # See https://gitlab.com/gitlab-org/gitlab/issues/7846
    prepended do
      include ::Emails::Epics
      include ::Emails::Requirements
      include ::Emails::UserCap
      include ::Emails::FreeUserCap
      include ::Emails::OncallRotation
      include ::Emails::GroupMemberships
      include ::Emails::InProductMarketing
      include ::Emails::MergeCommits
      include ::Emails::AbandonedTrialNotification
      include ::Emails::ComplianceFrameworks
    end

    attr_reader :group

    private

    override :reply_display_name
    def reply_display_name(model)
      return super unless model.is_a?(Epic)

      group.full_name
    end

    def add_group_headers
      headers['X-GitLab-Group-Id'] = group.id
      headers['X-GitLab-Group-Path'] = group.full_path
    end
  end
end
