# frozen_string_literal: true

module Llm
  class GenerateDescriptionService < BaseService
    extend ::Gitlab::Utils::Override
    SUPPORTED_ISSUABLE_TYPES = %w[issue work_item].freeze

    override :valid
    def valid?
      super &&
        Feature.enabled?(:generate_description_ai, resource) &&
        Ability.allowed?(user, :generate_description, resource)
    end

    private

    def perform
      worker_perform(user, resource, :generate_description, options)
    end
  end
end
