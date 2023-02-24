# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillNamespaceLdapSettings,
  :migration, feature_category: :system_access do
  let!(:namespaces) { table(:namespaces) }
  let!(:namespace_ldap_settings) { table(:namespace_ldap_settings) }

  let(:timestamp) { Time.new(2022, 1, 2).utc }

  let!(:namespace1) do
    namespaces.create!(
      name: 'group1',
      path: 'group1',
      ldap_sync_last_sync_at: timestamp,
      ldap_sync_last_update_at: timestamp + 1.minute,
      ldap_sync_last_successful_update_at: timestamp + 2.minutes,
      ldap_sync_error: nil)
  end

  let!(:namespace2) do
    namespaces.create!(
      name: 'group2',
      path: 'group2',
      ldap_sync_last_sync_at: timestamp + 4.minutes,
      ldap_sync_last_update_at: timestamp + 5.minutes,
      ldap_sync_last_successful_update_at: timestamp + 6.minutes,
      ldap_sync_error: 'Sync failed')
  end

  let(:migration1) do
    described_class.new(
      start_id: namespace1.id,
      end_id: namespace1.id,
      batch_table: 'namespaces',
      batch_column: 'id',
      sub_batch_size: 1,
      pause_ms: 0,
      connection: ApplicationRecord.connection)
  end

  let(:migration2) do
    described_class.new(
      start_id: namespace2.id,
      end_id: namespace2.id,
      batch_table: 'namespaces',
      batch_column: 'id',
      sub_batch_size: 1,
      pause_ms: 0,
      connection: ApplicationRecord.connection)
  end

  describe '#perform' do
    it 'migrates LDAP sync values by batch', :aggregate_failures do
      expect(namespace_ldap_settings.count).to eq(0)

      migration2.perform

      expect(namespace_ldap_settings.count).to eq(1)

      namespace2_ldap_settings = namespace_ldap_settings.find_by_namespace_id(namespace2.id)
      expect(namespace2_ldap_settings.sync_last_start_at).to eq(timestamp + 4.minutes)
      expect(namespace2_ldap_settings.sync_last_update_at).to eq(timestamp + 5.minutes)
      expect(namespace2_ldap_settings.sync_last_successful_at).to eq(timestamp + 6.minutes)
      expect(namespace2_ldap_settings.sync_error).to eq('Sync failed')

      migration1.perform

      expect(namespace_ldap_settings.count).to eq(2)

      namespace1_ldap_settings = namespace_ldap_settings.find_by_namespace_id(namespace1.id)
      expect(namespace1_ldap_settings.sync_last_start_at).to eq(timestamp)
      expect(namespace1_ldap_settings.sync_last_update_at).to eq(timestamp + 1.minute)
      expect(namespace1_ldap_settings.sync_last_successful_at).to eq(timestamp + 2.minutes)
      expect(namespace1_ldap_settings.sync_error).to eq(nil)
    end

    it 'does not create multiple entries or conflict on existing record' do
      migration1.perform

      expect(namespace_ldap_settings.count).to eq(1)

      migration1.perform

      expect(namespace_ldap_settings.count).to eq(1)
    end
  end
end
