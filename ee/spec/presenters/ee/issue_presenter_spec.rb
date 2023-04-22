# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssuePresenter do
  describe '#sla_due_at' do
    let_it_be(:incident) { build_stubbed(:incident) }
    let_it_be(:issuable_sla) { build_stubbed(:issuable_sla, issue: incident) }

    subject { described_class.new(incident).present.sla_due_at }

    before do
      allow(incident).to receive(:sla_available?).and_return(available)
    end

    context 'issue sla available' do
      let(:available) { true }

      it { is_expected.to eq(issuable_sla.due_at) }
    end

    context 'issue sla not available' do
      let(:available) { false }

      it { is_expected.to eq(nil) }
    end
  end

  describe '#web_url' do
    subject { described_class.new(issue).present.web_url }

    context 'when issue has default type' do
      let_it_be(:issue) { build_stubbed(:issue) }

      it { is_expected.to eq("http://localhost/#{issue.project.full_path}/-/issues/#{issue.iid}") }
    end

    context 'when issue has test_case type' do
      let_it_be(:issue) { build_stubbed(:quality_test_case) }

      it { is_expected.to eq("http://localhost/#{issue.project.full_path}/-/quality/test_cases/#{issue.iid}") }
    end
  end
end
