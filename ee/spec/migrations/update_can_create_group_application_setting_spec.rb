# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe UpdateCanCreateGroupApplicationSetting, :migration, feature_category: :subgroups do
  let(:application_setting) do
    Class.new(ActiveRecord::Base) do
      self.table_name = 'application_settings'
    end
  end

  shared_examples_for 'runs the migration successfully' do
    it 'runs the migration successfully' do
      reversible_migration do |migration|
        application_setting.create!

        migration.before -> {
          setting = application_setting.first

          expect(setting.can_create_group).to eq(true)
        }

        migration.after -> {
          application_setting.reset_column_information
          setting = application_setting.first

          expect(setting.can_create_group).to eq(expected_value_after_migration)
        }
      end
    end
  end

  context 'when the setting currently is set to `false` in the configuration file' do
    before do
      stub_config(gitlab: { default_can_create_group: false })
    end

    it_behaves_like 'runs the migration successfully' do
      let(:expected_value_after_migration) { false }
    end
  end

  context 'when the setting currently is set to `true` in the configuration file' do
    before do
      stub_config(gitlab: { default_can_create_group: true })
    end

    it_behaves_like 'runs the migration successfully' do
      let(:expected_value_after_migration) { true }
    end
  end

  context 'when the setting currently is set to `nil` in the configuration file' do
    before do
      stub_config(gitlab: { default_can_create_group: nil })
    end

    it_behaves_like 'runs the migration successfully' do
      let(:expected_value_after_migration) { true }
    end
  end

  context 'when the setting currently is set to a non-boolean value in the configuration file' do
    before do
      stub_config(gitlab: { default_can_create_group: 'something' })
    end

    it_behaves_like 'runs the migration successfully' do
      let(:expected_value_after_migration) { true }
    end
  end

  context 'when the setting is not present in the configuration file' do
    before do
      allow(Gitlab.config.gitlab).to receive(:respond_to?).with(:default_can_create_group).and_return(false)
    end

    it_behaves_like 'runs the migration successfully' do
      let(:expected_value_after_migration) { true }
    end
  end
end
