# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AbuseReport, feature_category: :insider_threat do
  describe '.create' do
    it 'calls the new abuse report worker' do
      expect(Abuse::NewAbuseReportWorker).to receive(:perform_async)
      create(:abuse_report)
    end
  end

  describe '#report_type' do
    let(:report) { build_stubbed(:abuse_report, reported_from_url: url) }
    let_it_be(:epic) { create(:epic) }

    subject(:report_type) { report.report_type }

    context 'when reported from an epic' do
      let(:url) { Gitlab::Routing.url_helpers.group_epic_url(epic.group, epic) }

      it { is_expected.to eq :epic }
    end
  end

  describe '#reported_content' do
    let(:report) { build_stubbed(:abuse_report, reported_from_url: url) }
    let_it_be(:epic) { create(:epic, description: 'epic description') }

    subject(:reported_content) { report.reported_content }

    context 'when reported from an epic' do
      let(:url) { Gitlab::Routing.url_helpers.group_epic_url(epic.group, epic) }

      it { is_expected.to eq epic.description_html }
    end
  end
end
