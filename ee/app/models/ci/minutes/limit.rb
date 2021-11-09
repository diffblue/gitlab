# frozen_string_literal: true

# This class is responsible for dealing with the CI minutes limits set at root namespace level.

module Ci
  module Minutes
    class Limit
      include Gitlab::Utils::StrongMemoize

      def initialize(namespace)
        @namespace = namespace
      end

      def enabled?
        namespace.root? && !unlimited?
      end

      def total
        monthly + purchased
      end

      def monthly
        strong_memoize(:monthly) do
          (namespace.shared_runners_minutes_limit || ::Gitlab::CurrentSettings.shared_runners_minutes).to_i
        end
      end

      def purchased
        strong_memoize(:purchased) do
          namespace.extra_shared_runners_minutes_limit.to_i
        end
      end

      def any_purchased?
        purchased > 0
      end

      private

      attr_reader :namespace

      def unlimited?
        total == 0
      end
    end
  end
end
