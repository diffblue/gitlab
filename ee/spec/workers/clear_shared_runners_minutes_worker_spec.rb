# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClearSharedRunnersMinutesWorker, feature_category: :continuous_integration do
  let(:worker) { described_class.new }

  describe '#perform' do
    subject { worker.perform }

    it 'does nothing and will be removed in the next release' do
      expect { subject }.not_to raise_error
    end
  end
end
