# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PackageMetadata::Ingestion::IngestionService, feature_category: :license_compliance do
  describe '.execute' do
    it 'raises an error because it is not implemented' do
      expect { described_class.execute(nil) }.to raise_error { NoMethodError }
    end
  end
end
