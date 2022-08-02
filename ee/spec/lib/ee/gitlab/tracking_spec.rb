# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Tracking do
  describe '.definition' do
    let_it_be(:test_definition) { { 'category': 'category', 'action': 'action' } }
    let_it_be(:filepath) { Rails.root.join('ee/config/events/filename.yml') }

    before do
      allow_next_instance_of(described_class) do |instance|
        allow(instance).to receive(:event)
      end
      allow_next_instance_of(Gitlab::Tracking::Destinations::Snowplow) do |instance|
        allow(instance).to receive(:event)
      end
      allow(YAML).to receive(:load_file).with(filepath).and_return(test_definition)
    end

    it 'fetch EE definitions when prefixed with ee_' do
      expect(YAML).to receive(:load_file).with(filepath)

      described_class.definition(+'ee_filename')
    end
  end
end
