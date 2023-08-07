# frozen_string_literal: true

module Gitlab
  module Llm
    class GraphqlSubscriptionResponseService < BaseService
      def initialize(user, resource, response_modifier, options:)
        @user = user
        @resource = resource
        @response_modifier = response_modifier
        @options = options
        @logger = Gitlab::Llm::Logger.build
      end

      def execute
        return unless user

        data = {
          id: SecureRandom.uuid,
          request_id: options[:request_id],
          model_name: resource&.class&.name,
          # todo: do we need to sanitize/refine this response in any ways?
          content: generate_response_body(response_modifier.response_body),
          errors: response_modifier.errors,
          role: Cache::ROLE_ASSISTANT,
          timestamp: Time.current
        }

        logger.debug(
          message: "Broadcasting AI response",
          data: data,
          options: options
        )

        response_data = data.slice(:request_id, :errors, :role, :content, :timestamp)

        unless options[:internal_request]
          Gitlab::Llm::Cache.new(user).add(response_data) if options[:cache_response]
          GraphqlTriggers.ai_completion_response(user.to_global_id, resource&.to_global_id, data)
        end

        response_data
      end

      private

      attr_reader :user, :resource, :response_modifier, :options, :logger

      def generate_response_body(response_body)
        return response_body if options[:markup_format].nil? || options[:markup_format].to_sym == :raw || resource.nil?

        banzai_options = { only_path: false, pipeline: :full, current_user: user }

        if resource.try(:project)
          banzai_options[:project] = resource.project
        elsif resource.try(:group)
          banzai_options[:group] = resource.group
          banzai_options[:skip_project_check] = true
        end

        Banzai.render_and_post_process(response_body, banzai_options)
      end
    end
  end
end
