# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::CreateSecuritySetting, :migration, schema: 20220326161803 do
  let(:projects) { table(:projects) }
  let(:settings) { table(:project_security_settings) }
  let(:namespaces) { table(:namespaces) }

  describe '#perform' do
    it 'adds setting object for existing projects' do
      namespace = namespaces.create!(name: 'test', path: 'test')
      projects.create!(id: 12, namespace_id: namespace.id, name: 'gitlab', path: 'gitlab')
      projects.create!(id: 13, namespace_id: namespace.id, name: 'sec_gitlab', path: 'sec_gitlab')
      projects.create!(id: 14, namespace_id: namespace.id, name: 'my_gitlab', path: 'my_gitlab')
      settings.create!(project_id: 13)

      expect { described_class.new.perform(12, 14) }.to change { settings.count }.from(1).to(3)
    end
  end
end
