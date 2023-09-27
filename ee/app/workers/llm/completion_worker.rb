# frozen_string_literal: true

module Llm
  class CompletionWorker
    include ApplicationWorker

    MAX_RUN_TIME = 20.seconds

    idempotent!
    data_consistency :delayed
    feature_category :ai_abstraction_layer
    urgency :low
    deduplicate :until_executed
    loggable_arguments 0, 1, 2, 3

    def perform(user_id, resource_id, resource_class, ai_action_name, options = {})
      start_time = ::Gitlab::Metrics::System.monotonic_time

      logger.debug(
        message: "Performing CompletionWorker",
        user_id: user_id,
        resource_id: resource_id,
        action_name: ai_action_name
      )

      return unless Feature.enabled?(:openai_experimentation)

      options.symbolize_keys!

      user = User.find_by_id(user_id)
      return unless user

      resource = find_resource(resource_id, resource_class)
      return if resource && !user.can?("read_#{resource.to_ability_name}", resource)

      options[:extra_resource] = ::Llm::ExtraResourceFinder.new(user, options.delete(:referer_url)).execute
      track_snowplow_event(user, ai_action_name, options)

      params = options.extract!(:request_id, :internal_request, :cache_response, :client_subscription_id)
      logger.debug(message: "Params", params: params)

      ai_completion = ::Gitlab::Llm::CompletionsFactory.completion(ai_action_name.to_sym, params)
      raise NameError, "completion class for action #{ai_action_name} not found" unless ai_completion

      logger.debug(message: "Getting Completion Service from factory", class_name: ai_completion.class.name)
      response = ai_completion.execute(user, resource, options)
      update_error_rate(ai_action_name, response)
      update_duration_metric(ai_action_name, ::Gitlab::Metrics::System.monotonic_time - start_time)

      response
    rescue StandardError => err
      update_error_rate(ai_action_name)

      raise err
    end

    private

    def update_error_rate(ai_action_name, response = nil)
      completion = ::Gitlab::Llm::CompletionsFactory::COMPLETIONS[ai_action_name.to_sym]
      return unless completion

      success = response.try(:errors)&.empty?

      Gitlab::Metrics::Sli::ErrorRate[:llm_completion].increment(
        labels: {
          feature_category: completion[:feature_category],
          service_class: completion[:service_class].name
        },
        error: !success
      )
    end

    def update_duration_metric(ai_action_name, duration)
      completion = ::Gitlab::Llm::CompletionsFactory::COMPLETIONS[ai_action_name.to_sym]
      return unless completion

      labels = {
        feature_category: completion[:feature_category],
        service_class: completion[:service_class].name
      }
      Gitlab::Metrics::Sli::Apdex[:llm_completion].increment(
        labels: labels,
        success: duration <= MAX_RUN_TIME
      )
    end

    def logger
      @logger ||= Gitlab::Llm::Logger.build
    end

    def find_resource(resource_id, resource_class)
      return unless resource_id

      resource_class.classify.constantize.find_by_id(resource_id)
    end

    def track_snowplow_event(user, action_name, options)
      Gitlab::Tracking.event(
        self.class.to_s,
        "perform_completion_worker",
        label: action_name.to_s,
        property: options[:request_id],
        user: user
      )
    end
  end
end
