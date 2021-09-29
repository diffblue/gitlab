# frozen_string_literal: true

module Admin
  module RepoSizeLimitHelper
    def repo_size_limit_feature_available?
      License.feature_available?(:repository_size_limit) || License.features_with_usage_ping.include?(:repository_size_limit)
    end
  end
end
