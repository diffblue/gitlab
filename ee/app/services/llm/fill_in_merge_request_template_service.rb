# frozen_string_literal: true

module Llm
  class FillInMergeRequestTemplateService < BaseService
    extend ::Gitlab::Utils::Override

    override :valid
    def valid?
      super &&
        resource.is_a?(Project) &&
        Ability.allowed?(user, :fill_in_merge_request_template, resource)
    end

    private

    def perform
      worker_perform(user, resource, :fill_in_merge_request_template, options)
    end
  end
end
