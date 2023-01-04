# frozen_string_literal: true

module Namespaces
  module FreeUserCap
    class RootSize < Namespaces::Storage::RootSize
      extend ::Gitlab::Utils::Override

      private

      override :valid_enforcement?
      def valid_enforcement?
        true
      end
    end
  end
end
