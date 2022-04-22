# frozen_string_literal: true

module NamespaceStorageHelpers
  def set_storage_size_limit(namespace, megabytes:)
    namespace.gitlab_subscription.hosted_plan.actual_limits.update!(storage_size_limit: megabytes)
  end

  def set_used_storage(namespace, megabytes:)
    namespace.root_storage_statistics.update!(storage_size: megabytes.megabytes)
  end
end
