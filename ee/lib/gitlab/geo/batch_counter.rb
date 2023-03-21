# frozen_string_literal: true

module Gitlab
  module Geo
    module BatchCounter
      # TODO: once the geo_batch_count FF is removed, we should also remove this module
      # and allow objects to use ::Gitlab::Database::BatchCount directly.
      # See issue: https://gitlab.com/gitlab-org/gitlab/-/issues/390748
      def batch_count(relation, column = nil)
        return yield unless batch_count_enabled?

        ::Gitlab::Database::BatchCount.batch_count(relation, column)
      end

      private

      def batch_count_enabled?
        Feature.enabled?(:geo_batch_count)
      end
    end
  end
end
