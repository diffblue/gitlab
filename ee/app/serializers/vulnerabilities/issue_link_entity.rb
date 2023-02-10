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

    def can_read_issue?
      can?(current_user, :read_issue, issue_link.issue)
    end

    # The request can be either nil or an instance of `EntityRequest`.
    # If the latter, it may or may not respond to `current_user` so that's
    # why we need to have the following guard clause.
    def current_user
      return request.current_user if request.respond_to?(:current_user)
    end
  end
end
