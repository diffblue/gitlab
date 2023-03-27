# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Emails::NamespaceStorageUsageMailer do
  include NamespacesHelper
  include EmailSpec::Matchers

  let_it_be(:namespace) { create(:namespace) }
  let_it_be(:usage_quotas_link) do
    ActionController::Base.helpers.link_to(namespace.name, usage_quotas_url(namespace, anchor: 'storage-quota-tab'))
  end

  let(:recipients) { %w(bob@example.com john@example.com) }

  describe '#notify_out_of_storage' do
    it 'creates an email message for a namespace', :aggregate_failures do
      mail = described_class.notify_out_of_storage(namespace: namespace, recipients: recipients,
        usage_values: {
          current_size: 101.megabytes,
          limit: 100.megabytes,
          used_storage_percentage: 101
        })

      expect(mail).to have_subject "Action required: Storage has been exceeded for #{namespace.name}"
      expect(mail).to bcc_to recipients
      expect(mail).to have_body_text(
        "You have used 101% of the storage quota for #{usage_quotas_link} (101 MB of 100 MB)"
      )
      expect(mail).to have_body_text buy_storage_url(namespace)
    end
  end

  describe '#notify_limit_warning' do
    it 'creates an email message for a namespace', :aggregate_failures do
      mail = described_class.notify_limit_warning(namespace: namespace, recipients: recipients,
        usage_values: {
          current_size: 75.megabytes,
          limit: 100.megabytes,
          used_storage_percentage: 75
        })

      expect(mail).to have_subject "You have used 75% of the storage quota for #{namespace.name}"
      expect(mail).to bcc_to recipients
      expect(mail).to have_body_text "You have used 75% of the storage quota for #{usage_quotas_link} (75 MB of 100 MB)"
      expect(mail).to have_body_text buy_storage_url(namespace)
    end
  end
end
