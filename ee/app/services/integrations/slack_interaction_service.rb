# frozen_string_literal: true

module Integrations
  class SlackInteractionService
    UnknownInteractionError = Class.new(StandardError)

    def initialize(params)
      @slack_interaction = params.delete(:type)
      @params = params
    end

    def execute
      if route_to_interactivity_worker?
        SlackInteractivityWorker.perform_async(slack_interaction: slack_interaction, params: params)

        return ServiceResponse.success
      end

      raise UnknownInteractionError, "Unable to handle interaction type: '#{slack_interaction}'"
    end

    private

    def route_to_interactivity_worker?
      SlackInteractivityWorker.interaction?(slack_interaction)
    end

    attr_reader :slack_interaction, :params
  end
end
