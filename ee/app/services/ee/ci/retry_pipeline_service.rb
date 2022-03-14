# frozen_string_literal: true

module EE
  module Ci
    module RetryPipelineService
      extend ::Gitlab::Utils::Override
      include ::Gitlab::Utils::StrongMemoize

      override :check_access
      def check_access(pipeline)
        if current_user && !current_user.has_required_credit_card_to_run_pipelines?(project)
          ServiceResponse.error(message: 'Credit card required to be on file in order to retry a pipeline', http_status: :forbidden)
        else
          super
        end
      end

      private

      override :builds_relation
      def builds_relation(pipeline)
        super.eager_load_tags
      end

      override :can_be_retried?
      def can_be_retried?(build)
        super && !ci_minutes_exceeded?(build)
      end

      def ci_minutes_exceeded?(build)
        !runner_minutes.available?(build.build_matcher)
      end

      def runner_minutes
        strong_memoize(:runner_minutes) do
          ::Gitlab::Ci::Minutes::RunnersAvailability.new(project)
        end
      end
    end
  end
end
