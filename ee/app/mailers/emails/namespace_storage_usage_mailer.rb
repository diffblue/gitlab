# frozen_string_literal: true

module Emails
  class NamespaceStorageUsageMailer < ApplicationMailer
    include NamespacesHelper
    include GitlabRoutingHelper

    helper EmailsHelper

    layout 'mailer'

    def notify_out_of_storage(namespace, recipients)
      @namespace = namespace
      @usage_quotas_url = usage_quotas_url(namespace, anchor: 'storage-quota-tab')
      @buy_storage_url = buy_storage_url(namespace)

      mail(
        bcc: recipients,
        subject: s_("NamespaceStorage|Action required: Storage has been exceeded for %{namespace_name}" % { namespace_name: namespace.name })
      )
    end

    def notify_limit_warning(namespace, recipients, percentage_of_available_storage)
      @namespace = namespace
      @usage_quotas_url = usage_quotas_url(namespace, anchor: 'storage-quota-tab')
      @buy_storage_url = buy_storage_url(namespace)
      @percentage_of_available_storage = percentage_of_available_storage

      mail(
        bcc: recipients,
        subject: s_("NamespaceStorage|Action required: Less than %{percentage_of_available_storage}%% of namespace storage remains for %{namespace_name}" %
                    { percentage_of_available_storage: percentage_of_available_storage, namespace_name: namespace.name })
      )
    end
  end
end
