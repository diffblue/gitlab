# frozen_string_literal: true

module Vulnerabilities
  class MergeRequestLinkEntity < Grape::Entity
    include RequestAwareEntity

    expose :merge_request_iid do |merge_request_link|
      merge_request_link.merge_request.iid
    end

    expose :merge_request_path, if: ->(_, _) { can_read_merge_request? } do |merge_request_link|
      project_merge_request_path(merge_request_link.vulnerability.project, merge_request_link.merge_request)
    end

    expose :author, using: UserEntity
    expose :created_at

    alias_method :merge_request_link, :object

    private

    def can_read_merge_request?
      can?(current_user, :read_merge_request, merge_request_link.merge_request)
    end

    # The request can be either nil or an instance of `EntityRequest`.
    # If the latter, it may or may not respond to `current_user` so that's
    # why we need to have the following guard clause.
    def current_user
      return request.current_user if request.respond_to?(:current_user)
    end
  end
end
