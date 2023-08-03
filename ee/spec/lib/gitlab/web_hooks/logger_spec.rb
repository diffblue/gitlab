# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::WebHooks::Logger, feature_category: :webhooks do
  describe '.build' do
    it 'builds an instance' do
      expect(described_class.build).to be_an_instance_of(described_class)
    end
  end
end
