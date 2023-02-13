# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PackageMetadata::SyncService, type: :worker, feature_category: :license_compliance do
  describe '.execute' do
    it 'is a stubbed service which is a noop when called' do
      expect { described_class.execute }.not_to raise_error
    end
  end
end
