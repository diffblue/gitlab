# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillNamespaceLdapSettings, feature_category: :system_access do
  describe '#up' do
    it 'schedules background migration' do
      migrate!

      expect(described_class::MIGRATION).to have_scheduled_batched_migration(
        table_name: :namespaces,
        column_name: :id,
        interval: described_class::INTERVAL)
    end
  end

  describe '#down' do
    it 'does not schedule background migration' do
      schema_migrate_down!

      expect(described_class::MIGRATION).not_to have_scheduled_batched_migration(
        table_name: :namespaces,
        column_name: :id,
        interval: described_class::INTERVAL)
    end
  end
end
