# frozen_string_literal: true

module Namespaces
  module FreeUserCap
    class EnforceableGroupsFinder
      def execute
        Group
          .in_default_plan
          .top_most
          .non_public_only
      end
    end
  end
end
