# frozen_string_literal: true

module Ci
  module Minutes
    class Context
      delegate :shared_runners_minutes_limit_enabled?, to: :namespace
      delegate :name, to: :namespace, prefix: true

      attr_reader :namespace

      def initialize(project, namespace, tracking_strategy: nil)
        @namespace = project&.shared_runners_limit_namespace || namespace
        @tracking_strategy = tracking_strategy
      end

      def percent_total_minutes_remaining
        quota.percent_total_minutes_remaining
      end

      private

      def quota
        @quota ||= ::Ci::Minutes::Quota.new(namespace, tracking_strategy: @tracking_strategy)
      end
    end
  end
end
