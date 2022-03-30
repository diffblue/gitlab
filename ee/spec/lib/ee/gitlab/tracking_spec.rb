# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Tracking do
  describe '.definition' do
    it 'fetch EE definitions when prefixed with ee_' do
      expect(YAML).to receive(:load_file).with(Rails.root.join('ee/config/events/filename.yml'))

      described_class.definition(+'ee_filename')
    end
  end
end
