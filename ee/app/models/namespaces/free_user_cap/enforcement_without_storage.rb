# frozen_string_literal: true

module Namespaces
  module FreeUserCap
    class EnforcementWithoutStorage < Enforcement
      private

      def above_size_limit?
        false
      end
    end
  end
end
