# frozen_string_literal: true

module NamespaceStorageHelpers
  def set_storage_size_limit(namespace, megabytes:)
    namespace.gitlab_subscription.hosted_plan.actual_limits.update!(storage_size_limit: megabytes)
  end

  def set_used_storage(namespace, megabytes:)
    namespace.root_storage_statistics.update!(storage_size: megabytes.megabytes)
  end

  def set_notification_limit(namespace, megabytes:)
    namespace.root_ancestor.actual_plan.actual_limits.update!(notification_limit: megabytes)
  end

  def enforce_namespace_storage_limit(root_namespace)
    stub_ee_application_setting(enforce_namespace_storage_limit: true)
    stub_ee_application_setting(automatic_purchased_storage_allocation: true)
    stub_const('::Namespaces::Storage::Enforcement::EFFECTIVE_DATE', 2.years.ago.to_date)
    stub_const('::Namespaces::Storage::Enforcement::ENFORCEMENT_DATE', 1.year.ago.to_date)
    stub_feature_flags(
      namespace_storage_limit: root_namespace,
      enforce_storage_limit_for_paid: root_namespace,
      enforce_storage_limit_for_free: root_namespace,
      namespace_storage_limit_bypass_date_check: false
    )
  end
end
