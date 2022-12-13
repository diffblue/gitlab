# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sbom::OccurrenceUUID, feature_category: :dependency_management do
  describe '.generate' do
    let(:params) do
      {
        project_id: 1,
        component_id: 2,
        component_version_id: 3,
        source_id: 4
      }
    end

    subject(:generate) { described_class.generate(**params) }

    it 'calls Gitlab::UUID with expected arguments' do
      expect(Gitlab::UUID).to receive(:v5).with('1-2-3-4').and_call_original
      expect(generate).to match(Gitlab::UUID::UUID_V5_PATTERN)
    end
  end
end
