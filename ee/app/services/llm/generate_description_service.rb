# frozen_string_literal: true

module Llm
  class GenerateDescriptionService < BaseService
    extend ::Gitlab::Utils::Override
    SUPPORTED_ISSUABLE_TYPES = %w[issue work_item].freeze

    override :valid
    def valid?
      super &&
        SUPPORTED_ISSUABLE_TYPES.include?(resource.to_ability_name) &&
        Feature.enabled?(:generate_description_ai, resource.resource_parent) &&
        Ability.allowed?(user, :generate_description, resource)
    end

    private

    def perform
      ::Llm::CompletionWorker.perform_async(user.id, resource.id, resource.class.name, :generate_description, options)
      success
    end
  end
end
