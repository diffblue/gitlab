# frozen_string_literal: true

module Namespaces
  module FreeUserCap
    class UsersFinder < ::Namespaces::BilledUsersFinder
      def self.count(group, limit)
        instance = new(group, limit)
        instance.execute
        instance.count
      end

      def initialize(group, limit)
        @group = group
        @limit = limit
        @ids = { user_ids: Set.new }
      end

      def count
        ids.transform_values(&:count)
      end

      private

      attr_reader :limit

      def calculate_user_ids(method_name)
        return if ids[:user_ids].count >= limit

        @ids[METHOD_KEY_MAP[method_name]] = group.public_send(method_name).limit(limit) # rubocop:disable GitlabSecurity/PublicSend
                                              .allow_cross_joins_across_databases(url: "https://gitlab.com/gitlab-org/gitlab/-/issues/417464")
                                              .pluck(:id).to_set # rubocop:disable CodeReuse/ActiveRecord

        append_to_user_ids(ids[METHOD_KEY_MAP[method_name]])
      end
    end
  end
end
