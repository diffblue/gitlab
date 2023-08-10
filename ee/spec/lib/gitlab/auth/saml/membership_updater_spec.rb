# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::Saml::MembershipUpdater, feature_category: :system_access do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  let_it_be(:group_link) { create(:saml_group_link, saml_group_name: 'Org Users', group: group) }

  let_it_be_with_refind(:application) { create(:system_access_microsoft_application, enabled: true, namespace: nil) }

  let_it_be(:all_groups) { ['Org Users', 'Dept Users'] }
  let_it_be(:no_groups) { [] }

  def stub_saml_group_sync_enabled(enabled)
    allow_next_instance_of(::Gitlab::Auth::Saml::Config) do |instance|
      allow(instance).to receive_messages(
        group_sync_enabled?: enabled,
        microsoft_group_sync_enabled?: enabled,
        groups: 'groups'
      )
    end
  end

  def stub_microsoft_groups(groups)
    allow_next_instance_of(::Microsoft::GraphClient) do |instance|
      allow(instance).to receive_messages(user_group_membership_object_ids: groups)
    end
  end

  def build_auth_hash(groups:, overage:)
    raw_info = if groups.present?
                 OneLogin::RubySaml::Attributes.new('groups' => groups)
               elsif overage
                 OneLogin::RubySaml::Attributes.new({
                   'http://schemas.microsoft.com/claims/groups.link' =>
                     ['https://graph.windows.net/8c750e43/users/e631c82c/getMemberObjects']
                 })
               else
                 OneLogin::RubySaml::Attributes.new
               end

    Gitlab::Auth::Saml::AuthHash.new(OmniAuth::AuthHash.new(provider: 'saml', extra: { raw_info: raw_info }))
  end

  using RSpec::Parameterized::TableSyntax

  where(:sync_enabled, :app_enabled, :groups, :microsoft_groups, :expect_saml_worker, :expect_microsoft_worker) do
    false | false | ref(:all_groups) | ref(:no_groups)  | false | false
    false | true  | ref(:all_groups) | ref(:no_groups)  | false | false

    false | false | ref(:no_groups)  | ref(:all_groups) | false | false
    false | true  | ref(:no_groups)  | ref(:all_groups) | false | false

    true  | false | ref(:all_groups) | ref(:no_groups)  | true  | false
    true  | true  | ref(:all_groups) | ref(:no_groups)  | true  | false
    true  | false | ref(:no_groups)  | ref(:all_groups) | true  | false
    true  | true  | ref(:no_groups)  | ref(:all_groups) | false | true
  end

  with_them do
    before do
      stub_saml_group_sync_enabled(sync_enabled)
      application.update!(enabled: app_enabled)
      stub_microsoft_groups(microsoft_groups)
    end

    def expect_saml_worker_call(expect_call, *args)
      return expect(Auth::SamlGroupSyncWorker).not_to receive(:perform_async) unless expect_call

      expect(Auth::SamlGroupSyncWorker).to receive(:perform_async).with(*args)
    end

    def expect_microsoft_worker_call(expect_call, *args)
      return expect(::SystemAccess::SamlMicrosoftGroupSyncWorker).not_to receive(:perform_async) unless expect_call

      expect(::SystemAccess::SamlMicrosoftGroupSyncWorker).to receive(:perform_async).with(*args)
    end

    it 'calls the appropriate sync worker' do
      group_links = groups.include?(group_link.saml_group_name) ? [group_link.id] : []

      expect_saml_worker_call(expect_saml_worker, user.id, group_links, 'saml')
      expect_microsoft_worker_call(expect_microsoft_worker, user.id, 'saml')

      auth_hash = build_auth_hash(groups: groups, overage: microsoft_groups.present?)
      membership_updater = described_class.new(user, auth_hash)

      membership_updater.execute
    end
  end
end
