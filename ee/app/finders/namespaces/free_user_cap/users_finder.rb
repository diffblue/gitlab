# frozen_string_literal: true

module Namespaces
  module FreeUserCap
    class UsersFinder < ::Namespaces::BilledUsersFinder
      def self.count(group)
        instance = new(group)
        instance.execute
        instance.count
      end

      def count
        ids[:user_ids].count
      end
    end
  end
end
