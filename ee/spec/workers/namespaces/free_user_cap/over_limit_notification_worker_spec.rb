# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::FreeUserCap::OverLimitNotificationWorker, :saas, type: :worker, feature_category: :measurement_and_locking do
  describe '#perform' do
    subject(:worker) { described_class.new }

    it 'does not do anything' do
      expect(worker.perform).to be_nil
    end
  end
end
