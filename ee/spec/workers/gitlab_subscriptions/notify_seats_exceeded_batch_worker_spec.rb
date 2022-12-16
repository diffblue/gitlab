# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSubscriptions::NotifySeatsExceededBatchWorker, feature_category: :billing_and_payments do
  describe '#perform' do
    it 'calls NotifySeatsExceededBatchService' do
      expect(GitlabSubscriptions::NotifySeatsExceededBatchService).to receive(:execute)

      described_class.new.perform
    end
  end
end
