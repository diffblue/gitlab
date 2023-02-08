# frozen_string_literal: true

module Vulnerabilities
  class IssueLinkEntity < Grape::Entity
    include RequestAwareEntity

    expose :issue_iid do |issue_link|
      issue_link.issue.iid
    end

    expose :issue_url, if: ->(_, _) { can_read_issue? } do |issue_link|
      project_issue_url(issue_link.vulnerability.project, issue_link.issue)
    end

    expose :author, using: UserEntity
    expose :created_at
    expose :link_type

    alias_method :issue_link, :object

    private

    # Security reports serialise findings, which include this entity.
    # As these reports are created in Sidekiq, request is nil
    delegate :current_user, to: :request, allow_nil: true

    def can_read_issue?
      can?(current_user, :read_issue, issue_link.issue)
    end
  end
end
