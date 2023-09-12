# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CompareLicenseScanningReportsCollapsedService, feature_category: :software_composition_analysis do
  include ProjectForksHelper

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:merge_request) { create(:ee_merge_request, :with_dependency_scanning_reports, source_project: project) }

  let(:service) do
    described_class.new(
      project,
      nil,
      report_type: 'license_scanning',
      id: merge_request.id
    )
  end

  before do
    stub_licensed_features(license_scanning: true)
  end

  describe '#execute' do
    subject { service.execute(base_pipeline, head_pipeline) }

    context 'when base and head pipelines have test reports' do
      let_it_be(:base_pipeline) { create(:ee_ci_pipeline, :with_license_scanning_report, project: project) }
      let_it_be(:head_pipeline) { create(:ee_ci_pipeline, :with_license_scanning_feature_branch, project: project) }

      context 'with denied licenses' do
        context 'with incorrect report type' do
          before do
            allow_next_instance_of(::SCA::LicensePolicy) do |license|
              allow(license).to receive(:approval_status).and_return('denied')
            end
          end

          it 'does not process the report' do
            expect(subject[:status]).to eq(:parsed)
            expect(subject[:data]['new_licenses']).to eq(0)
            expect(subject[:data]['existing_licenses']).to eq(0)
            expect(subject[:data]['removed_licenses']).to eq(0)
            expect(subject[:data]['approval_required']).to eq(false)
            expect(subject[:data]['has_denied_licenses']).to eq(false)
          end

          context 'when license_check enabled' do
            let_it_be(:license_check) { create(:report_approver_rule, :license_scanning, merge_request: merge_request) }

            it 'does not process the report' do
              expect(subject[:data]['approval_required']).to eq(false)
              expect(subject[:data]['has_denied_licenses']).to eq(false)
            end
          end
        end

        context 'with cyclonedx report' do
          let_it_be(:base_pipeline) { create(:ee_ci_pipeline, :with_cyclonedx_report, project: project) }
          let_it_be(:head_pipeline) { create(:ee_ci_pipeline, :with_cyclonedx_pypi_only, project: project) }

          before do
            create(:pm_package, name: "nokogiri", purl_type: "gem",
              other_licenses: [{ license_names: ["BSD-3-Clause"], versions: ["1.8.0"] }])
            create(:pm_package, name: "django", purl_type: "pypi",
              other_licenses: [{ license_names: ["MIT"], versions: ["1.11.4"] }])

            allow_next_instance_of(::SCA::LicensePolicy) do |license|
              allow(license).to receive(:approval_status).and_return('denied')
            end
          end

          it 'exposes report with numbers of licenses by type' do
            expect(subject[:status]).to eq(:parsed)
            expect(subject[:data]['new_licenses']).to eq(1)
            expect(subject[:data]['existing_licenses']).to eq(1)
            expect(subject[:data]['removed_licenses']).to eq(1)
            expect(subject[:data]['approval_required']).to eq(false)
            expect(subject[:data]['has_denied_licenses']).to eq(true)
          end

          context 'when license_check enabled' do
            let_it_be(:license_check) do
              create(:report_approver_rule, :license_scanning, merge_request: merge_request)
            end

            it 'exposes approval as required' do
              expect(subject[:data]['approval_required']).to eq(true)
              expect(subject[:data]['has_denied_licenses']).to eq(true)
            end
          end
        end
      end

      context 'without denied licenses' do
        let_it_be(:base_pipeline) { create(:ee_ci_pipeline, :with_cyclonedx_report, project: project) }
        let_it_be(:head_pipeline) { create(:ee_ci_pipeline, :with_cyclonedx_pypi_only, project: project) }

        before do
          create(:pm_package, name: "nokogiri", purl_type: "gem",
            other_licenses: [{ license_names: ["BSD-3-Clause"], versions: ["1.8.0"] }])
          create(:pm_package, name: "django", purl_type: "pypi",
            other_licenses: [{ license_names: ["MIT"], versions: ["1.11.4"] }])
        end

        it 'exposes approval as not required' do
          expect(subject[:data]['approval_required']).to eq(false)
          expect(subject[:data]['has_denied_licenses']).to eq(false)
        end
      end
    end

    context 'when head pipeline has corrupted reports' do
      let_it_be(:base_pipeline) { build(:ee_ci_pipeline, :with_corrupted_cyclonedx_report, project: project) }
      let_it_be(:head_pipeline) { build(:ee_ci_pipeline, :with_corrupted_cyclonedx_report, project: project) }

      it 'exposes empty report' do
        expect(subject[:status]).to eq(:parsed)
        expect(subject[:data]['new_licenses']).to eq(0)
        expect(subject[:data]['existing_licenses']).to eq(0)
        expect(subject[:data]['removed_licenses']).to eq(0)
        expect(subject[:data]['approval_required']).to eq(false)
      end

      context "when the base pipeline is nil" do
        subject { service.execute(nil, head_pipeline) }

        it 'exposes empty report' do
          expect(subject[:status]).to eq(:parsed)
          expect(subject[:data]['new_licenses']).to eq(0)
          expect(subject[:data]['existing_licenses']).to eq(0)
          expect(subject[:data]['removed_licenses']).to eq(0)
          expect(subject[:data]['approval_required']).to eq(false)
        end
      end
    end
  end

  describe '#serializer_class' do
    subject { service.serializer_class }

    it { is_expected.to be(::LicenseCompliance::CollapsedComparerSerializer) }
  end
end
