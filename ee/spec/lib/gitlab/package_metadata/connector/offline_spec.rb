# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::PackageMetadata::Connector::Offline, feature_category: :license_compliance do
  describe '#data_after' do
    subject(:instance) { described_class.new('path', 'v1', 'composer') }

    it 'raises an error because it is not implemented' do
      expect { instance.data_after(nil) }.to raise_error { NoMethodError }
    end
  end
end
