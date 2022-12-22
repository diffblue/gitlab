# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::FindingReportsComparerEntity, feature_category: :vulnerability_management do
  describe 'container scanning report comparison' do
    let_it_be(:user) { create(:user) }

    let(:project) { build(:project) }
    let(:base_findings) { create_list(:vulnerabilities_finding, 2) }
    let(:base_combined_reports) { build_list(:ci_reports_security_report, 1, created_at: nil) }
    let(:base_report) { build(:ci_reports_security_aggregated_reports, reports: base_combined_reports, findings: base_findings) }

    let(:head_findings) { create_list(:vulnerabilities_finding, 1) }
    let(:head_combined_reports) { build_list(:ci_reports_security_report, 1, created_at: 2.days.ago) }
    let(:head_report) { build(:ci_reports_security_aggregated_reports, reports: head_combined_reports, findings: head_findings) }

    let(:comparer) { Gitlab::Ci::Reports::Security::VulnerabilityReportsComparer.new(project, base_report, head_report) }

    let(:request) { double('request') }

    let(:entity) { described_class.new(comparer, request: request) }

    before do
      stub_licensed_features(container_scanning: true)
    end

    describe '#as_json' do
      subject { entity.as_json }

      before do
        allow(request).to receive(:current_user).and_return(user)
      end

      it 'contains the added and fixed vulnerabilities for container scanning' do
        expect(subject.keys).to include(:added)
        expect(subject.keys).to include(:fixed)
      end

      it 'contains the report out of date fields' do
        expect(subject.keys).to include(:base_report_created_at)
        expect(subject.keys).to include(:base_report_out_of_date)
        expect(subject.keys).to include(:head_report_created_at)
      end
    end
  end
end
