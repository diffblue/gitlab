# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Emails::NamespaceStorageUsageMailer do
  include EmailSpec::Matchers

  let_it_be(:group) { create(:group) }
  let_it_be(:namespace) { create(:namespace) }

  let(:recipients) { %w(bob@example.com john@example.com) }

  describe '#notify_out_of_storage' do
    it 'creates an email message for a group' do
      mail = described_class.notify_out_of_storage(group, recipients)

      expect(mail).to have_subject "Action required: Storage has been exceeded for #{group.name}"
      expect(mail).to bcc_to recipients
      expect(mail).to have_body_text "#{usage_quotas_url(group, anchor: 'storage-quota-tab')}"
      expect(mail).to have_body_text "has exceeded its namespace storage limit"
      expect(mail).to have_body_text "#{buy_storage_subscriptions_url(selected_group: group.id)}"
    end

    it 'creates an email message for a namespace' do
      mail = described_class.notify_out_of_storage(namespace, recipients)

      expect(mail).to have_subject "Action required: Storage has been exceeded for #{namespace.name}"
      expect(mail).to bcc_to recipients
      expect(mail).to have_body_text "#{usage_quotas_url(namespace, anchor: 'storage-quota-tab')}"
      expect(mail).to have_body_text "has exceeded its namespace storage limit"
      expect(mail).to have_body_text EE::SUBSCRIPTIONS_MORE_STORAGE_URL
    end
  end

  describe '#notify_limit_warning' do
    it 'creates an email message for a group' do
      mail = described_class.notify_limit_warning(group, recipients, 25)

      expect(mail).to have_subject "Action required: Less than 25% of namespace storage remains for #{group.name}"
      expect(mail).to bcc_to recipients
      expect(mail).to have_body_text "#{usage_quotas_url(group, anchor: 'storage-quota-tab')}"
      expect(mail).to have_body_text "has 25% or less namespace storage space remaining"
      expect(mail).to have_body_text "#{buy_storage_subscriptions_url(selected_group: group.id)}"
    end

    it 'creates an email message for a namespace' do
      mail = described_class.notify_limit_warning(namespace, recipients, 30)

      expect(mail).to have_subject "Action required: Less than 30% of namespace storage remains for #{namespace.name}"
      expect(mail).to bcc_to recipients
      expect(mail).to have_body_text "#{usage_quotas_url(namespace, anchor: 'storage-quota-tab')}"
      expect(mail).to have_body_text "has 30% or less namespace storage space remaining"
      expect(mail).to have_body_text EE::SUBSCRIPTIONS_MORE_STORAGE_URL
    end
  end
end
