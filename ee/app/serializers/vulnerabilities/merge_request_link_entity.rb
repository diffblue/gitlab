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

    # Security reports serialise findings, which include this entity.
    # As these reports are created in Sidekiq, request is nil
    delegate :current_user, to: :request, allow_nil: true

    def can_read_merge_request?
      can?(current_user, :read_merge_request, merge_request_link.merge_request)
    end
  end
end
