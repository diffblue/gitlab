# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillDelayedGroupDeletion, :migration, feature_category: :subgroups do
  let(:application_setting) do
    Class.new(ActiveRecord::Base) do
      self.table_name = 'application_settings'
    end
  end

  it 'correctly runs the migration' do
    reversible_migration do |migration|
      application_setting.create!

      migration.before -> {
        setting = application_setting.first

        expect(setting.delayed_group_deletion).to eq(true)
      }

      migration.after -> {
        application_setting.reset_column_information
        setting = application_setting.first

        expect(setting.delayed_group_deletion).to eq(setting.deletion_adjourned_period > 0)
      }
    end
  end
end
