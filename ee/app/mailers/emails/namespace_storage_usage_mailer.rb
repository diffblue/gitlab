# frozen_string_literal: true

module Emails
  class NamespaceStorageUsageMailer < ApplicationMailer
    include NamespacesHelper
    include GitlabRoutingHelper

    helper EmailsHelper

    layout 'mailer'

    def notify_out_of_storage(namespace:, recipients:, usage_values:)
      @namespace = namespace
      @usage_quotas_url = usage_quotas_url(namespace, anchor: 'storage-quota-tab')
      @buy_storage_url = buy_storage_url(namespace)
      @current_size = usage_values[:current_size]
      @limit = usage_values[:limit]
      @used_storage_percentage = usage_values[:used_storage_percentage]

      mail_with_locale(
        bcc: recipients,
        subject: s_("NamespaceStorage|Action required: Storage has been exceeded for %{namespace_name}" % { namespace_name: namespace.name })
      )
    end

    def notify_limit_warning(namespace:, recipients:, usage_values:)
      @namespace = namespace
      @usage_quotas_url = usage_quotas_url(namespace, anchor: 'storage-quota-tab')
      @buy_storage_url = buy_storage_url(namespace)
      @current_size = usage_values[:current_size]
      @limit = usage_values[:limit]
      @used_storage_percentage = usage_values[:used_storage_percentage]

      mail_with_locale(
        bcc: recipients,
        subject: s_("NamespaceStorage|You have used %{used_storage_percentage}%% of the storage quota for %{namespace_name}" %
          { used_storage_percentage: @used_storage_percentage, namespace_name: namespace.name })
      )
    end
  end
end
