# frozen_string_literal: true

module Mutations
  module Ai
    class Action < BaseMutation
      graphql_name 'AiAction'

      MUTUALLY_EXCLUSIVE_ARGUMENTS_ERROR = 'Only one method argument is required'

      Llm::ExecuteMethodService::METHODS.each_key do |method|
        argument method,
          "Types::Ai::#{method.to_s.camelize}InputType".constantize,
          required: false,
          description: "Input for #{method} AI action."
      end

      argument :markup_format, EE::Types::MarkupFormatEnum,
        required: false,
        description: 'Indicates the response format.',
        default_value: :raw

      def ready?(**args)
        raise Gitlab::Graphql::Errors::ArgumentError, MUTUALLY_EXCLUSIVE_ARGUMENTS_ERROR if methods(args).size != 1

        super
      end

      def resolve(**attributes)
        check_feature_flag_enabled!
        verify_rate_limit!

        resource_id, method, options = extract_method_params!(attributes)
        resource = authorized_find!(id: resource_id)

        response = Llm::ExecuteMethodService.new(current_user, resource, method, options).execute

        {
          errors: response.success? ? [] : [response.message]
        }
      end

      private

      def check_feature_flag_enabled!
        return if Feature.enabled?(:openai_experimentation)

        raise Gitlab::Graphql::Errors::ResourceNotAvailable, '`openai_experimentation` feature flag is disabled.'
      end

      def verify_rate_limit!
        return unless Gitlab::ApplicationRateLimiter.throttled?(:ai_action, scope: [current_user])

        raise Gitlab::Graphql::Errors::ResourceNotAvailable,
          'This endpoint has been requested too many times. Try again later.'
      end

      def methods(args)
        args.slice(*Llm::ExecuteMethodService::METHODS.keys)
      end

      def find_object(id:)
        GitlabSchema.object_from_id(id, expected_type: ::Ai::Model)
      end

      def authorized_resource?(object)
        return unless object

        object.resource_parent.member?(current_user) &&
          current_user.can?("read_#{object.to_ability_name}", object)
      end

      def extract_method_params!(attributes)
        options = attributes.extract!(:markup_format)
        methods = methods(attributes.transform_values(&:to_h))

        # At this point, we only have one method since we filtered it in `#ready?`
        # so we can safely get the first.
        method = methods.each_key.first
        method_arguments = options.merge(methods[method])

        [method_arguments.delete(:resource_id), method, method_arguments]
      end
    end
  end
end
