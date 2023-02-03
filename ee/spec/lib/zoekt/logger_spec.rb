# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Zoekt::Logger, feature_category: :global_search do
  describe '.build' do
    it 'builds an instance' do
      expect(described_class.build).to be_an_instance_of(described_class)
    end
  end
end
