# frozen_string_literal: true

module EE
  module Ci
    module JobsFinder
      extend ::Gitlab::Utils::Override

      private

      override :filter_builds
      def filter_builds(builds)
        filter_by_failure_reason(super)
      end

      override :use_runner_type_filter?
      def use_runner_type_filter?
        # we don't need to use the runner_type scope if we know that the user only cares about instance runners
        # with a job failure reason
        return false if use_failure_reason_filter?

        super
      end

      def filter_by_failure_reason(builds)
        return builds unless use_failure_reason_filter?

        builds.recently_failed_on_instance_runner(params[:failure_reason]) # currently limited to instance runners
      end

      def use_failure_reason_filter?
        failure_reason = params[:failure_reason]
        runner_type = params[:runner_type]

        if failure_reason.present?
          unless failure_reason == :runner_system_failure
            raise ArgumentError, 'failure_reason only supports runner_system_failure'
          end

          unless runner_type == %w[instance_type]
            raise ArgumentError, 'failure_reason can only be used together with runner_type: instance_type'
          end

          return true
        end

        false
      end
    end
  end
end
