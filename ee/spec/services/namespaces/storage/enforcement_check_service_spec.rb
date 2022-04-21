# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Namespaces::Storage::EnforcementCheckService do
  let_it_be(:group) { create(:group) }

  describe '.enforce_limit?' do
    before do
      stub_feature_flags(namespace_storage_limit: group)
      stub_application_setting(enforce_namespace_storage_limit: true)
    end

    it 'returns true when namespace storage limits are enforced for the namespace' do
      expect(described_class.enforce_limit?(group)).to eq(true)
    end

    it 'returns false when the feature flag is disabled' do
      stub_feature_flags(namespace_storage_limit: false)

      expect(described_class.enforce_limit?(group)).to eq(false)
    end

    it 'returns false when the application setting is disabled' do
      stub_application_setting(enforce_namespace_storage_limit: false)

      expect(described_class.enforce_limit?(group)).to eq(false)
    end
  end
end
