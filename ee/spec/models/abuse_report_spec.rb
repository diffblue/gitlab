# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AbuseReport, feature_category: :insider_threat do
  describe '.create' do
    it 'calls the new abuse report worker' do
      expect(Abuse::NewAbuseReportWorker).to receive(:perform_async)
      create(:abuse_report)
    end
  end
end
