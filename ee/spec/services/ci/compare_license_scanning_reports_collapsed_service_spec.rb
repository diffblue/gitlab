# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CompareLicenseScanningReportsCollapsedService do
  include ProjectForksHelper

  let_it_be(:project) { create(:project, :repository) }

  let(:service) do
    described_class.new(
      project,
      nil,
      report_type: 'license_scanning',
      additional_params: { license_check: license_check }
    )
  end

  let(:license_check) { false }

  before do
    stub_licensed_features(license_scanning: true)
  end

  describe '#execute' do
    subject { service.execute(base_pipeline, head_pipeline) }

    context 'when base and head pipelines have test reports' do
      let_it_be(:base_pipeline) { create(:ee_ci_pipeline, :with_license_scanning_report, project: project) }
      let_it_be(:head_pipeline) { create(:ee_ci_pipeline, :with_license_scanning_feature_branch, project: project) }

      context 'with denied licenses' do
        before do
          allow_next_instance_of(::SCA::LicensePolicy) do |license|
            allow(license).to receive(:approval_status).and_return('denied')
          end
        end

        it 'exposes report with numbers of licenses by type' do
          expect(subject[:status]).to eq(:parsed)
          expect(subject[:data]['new_licenses']).to eq(1)
          expect(subject[:data]['existing_licenses']).to eq(1)
          expect(subject[:data]['removed_licenses']).to eq(3)
          expect(subject[:data]['approval_required']).to eq(false)
          expect(subject[:data]['has_denied_licenses']).to eq(true)
        end

        context 'when license_check enabled' do
          let(:license_check) { true }

          it 'exposes approval as required' do
            expect(subject[:data]['approval_required']).to eq(true)
            expect(subject[:data]['has_denied_licenses']).to eq(true)
          end
        end
      end

      context 'without denied licenses' do
        it 'exposes approval as not required' do
          expect(subject[:data]['approval_required']).to eq(false)
          expect(subject[:data]['has_denied_licenses']).to eq(false)
        end
      end
    end

    context 'when head pipeline has corrupted license scanning reports' do
      let_it_be(:base_pipeline) { build(:ee_ci_pipeline, :with_corrupted_license_scanning_report, project: project) }
      let_it_be(:head_pipeline) { build(:ee_ci_pipeline, :with_corrupted_license_scanning_report, project: project) }

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
