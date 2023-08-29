# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportSources, feature_category: :importers do
  describe '.import_table' do
    it 'includes specific EE imports types when the license supports them' do
      stub_licensed_features(custom_project_templates: true)

      expect(described_class.ee_import_table).not_to be_empty
      expect(described_class.import_table).to include(*described_class.ee_import_table)
    end
  end
end
