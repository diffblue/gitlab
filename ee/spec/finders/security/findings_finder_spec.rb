# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::FindingsFinder, feature_category: :vulnerability_management do
  it_behaves_like 'security findings finder' do
    let(:findings) { service_object.execute.findings }
    let(:query_limit) { 16 }

    context 'when the `security_findings` records have `overridden_uuid`s' do
      let(:security_findings) { Security::Finding.by_build_ids(build_1) }
      let(:expected_uuids) do
        Security::Finding.where(overridden_uuid: nil).pluck(:uuid)
          .concat(Security::Finding.where.not(overridden_uuid: nil).pluck(:overridden_uuid)) -
          [Security::Finding.second[:overridden_uuid]]
      end

      subject { findings.map(&:uuid) }

      before do
        security_findings.each do |security_finding|
          security_finding.update!(overridden_uuid: security_finding.uuid, uuid: SecureRandom.uuid)
        end
      end

      it { is_expected.to match_array(expected_uuids) }
    end

    describe '#vulnerability_flags' do
      before do
        stub_licensed_features(sast_fp_reduction: true)
      end

      context 'with no vulnerability flags present' do
        it 'does not have any vulnerability flag' do
          expect(findings).to all(have_attributes(vulnerability_flags: be_empty))
        end
      end

      context 'with some vulnerability flags present' do
        before do
          allow_next_instance_of(Gitlab::Ci::Reports::Security::Finding) do |finding|
            allow(finding).to receive(:flags).and_return([create(:ci_reports_security_flag)]) if finding.report_type == 'sast'
          end
        end

        it 'has some vulnerability_findings with vulnerability flag' do
          expect(findings).to include(have_attributes(vulnerability_flags: be_present))
        end

        it 'does not have any vulnerability_flag if license is not available' do
          stub_licensed_features(sast_fp_reduction: false)

          expect(findings).to all(have_attributes(vulnerability_flags: be_empty))
        end
      end
    end
  end
end
