# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CompareLicenseScanningReportsService do
  include ProjectForksHelper

  let_it_be(:project) { create(:project, :repository) }

  let(:service) { described_class.new(project, nil) }

  before do
    stub_licensed_features(license_scanning: true)
  end

  describe '#execute' do
    subject { service.execute(base_pipeline, head_pipeline) }

    context "when loading data for multiple reports" do
      it 'loads the data efficiently' do
        base_pipeline = create(:ci_pipeline, :success, project: project)
        head_pipeline = create(:ci_pipeline, :success, project: project, builds: [create(:ci_build, :success, job_artifacts: [create(:ee_ci_job_artifact, :license_scan)])])

        control_count = ActiveRecord::QueryRecorder.new do
          service.execute(base_pipeline.reload, head_pipeline.reload)
        end.count

        new_head_pipeline = create(:ci_pipeline, :success, project: project, builds: [create(:ee_ci_build, :license_scan_v2_1, :success)])

        expect do
          service.execute(base_pipeline.reload, new_head_pipeline.reload)
        end.not_to exceed_query_limit(control_count)
      end
    end

    context 'when head pipeline has license scanning reports' do
      let!(:base_pipeline) { nil }
      let!(:head_pipeline) { create(:ee_ci_pipeline, :with_license_scanning_report, project: project) }

      context 'when the license_scanning_sbom_scanner feature flag is false' do
        before do
          stub_feature_flags(license_scanning_sbom_scanner: false)
        end

        it 'reports new licenses' do
          expect(subject[:status]).to eq(:parsed)
          expect(subject[:data]['new_licenses'].count).to eq(4)
          expect(subject[:data]['new_licenses']).to include(a_hash_including('name' => 'MIT'))
        end
      end
    end

    context "when head pipeline has not run and base pipeline is for a forked project" do
      let(:service) { described_class.new(project, maintainer) }
      let(:maintainer) { create(:user) }
      let(:contributor) { create(:user) }
      let(:project) { create(:project, :public, :repository) }
      let(:base_pipeline) { nil }
      let(:head_pipeline) { create(:ee_ci_pipeline, :with_license_scanning_report, project: forked_project, user: contributor) }
      let(:forked_project) { fork_project(project, contributor, namespace: contributor.namespace) }

      before do
        project.add_maintainer(maintainer)
        project.add_developer(contributor)
      end

      context 'when the license_scanning_sbom_scanner feature flag is false' do
        before do
          stub_feature_flags(license_scanning_sbom_scanner: false)
        end

        it 'reports new licenses' do
          expect(subject[:status]).to eq(:parsed)
          expect(subject[:data]['new_licenses'].count).to be > 1
        end
      end
    end

    context 'when base and head pipelines have test reports' do
      let!(:base_pipeline) { create(:ee_ci_pipeline, :with_license_scanning_report, project: project) }
      let!(:head_pipeline) { create(:ee_ci_pipeline, :with_license_scanning_feature_branch, project: project) }

      it 'reports status as parsed' do
        expect(subject[:status]).to eq(:parsed)
      end

      context 'when the license_scanning_sbom_scanner feature flag is false' do
        before do
          stub_feature_flags(license_scanning_sbom_scanner: false)
        end

        it 'reports new licenses' do
          expect(subject[:data]['new_licenses'].count).to eq(1)
          expect(subject[:data]['new_licenses']).to include(a_hash_including('name' => 'WTFPL'))
        end

        it 'reports existing licenses' do
          expect(subject[:data]['existing_licenses'].count).to eq(1)
          expect(subject[:data]['existing_licenses']).to include(a_hash_including('name' => 'MIT'))
        end

        it 'reports removed licenses' do
          expect(subject[:data]['removed_licenses'].count).to eq(3)
          expect(subject[:data]['removed_licenses']).to include(a_hash_including('name' => 'New BSD'))
        end
      end
    end

    context 'when head pipeline has corrupted license scanning reports' do
      let!(:base_pipeline) { build(:ee_ci_pipeline, :with_corrupted_license_scanning_report, project: project) }
      let!(:head_pipeline) { build(:ee_ci_pipeline, :with_corrupted_license_scanning_report, project: project) }

      it 'does not expose parser errors' do
        expect(subject[:status]).to eq(:parsed)
      end

      context "when the base pipeline is nil" do
        subject { service.execute(nil, head_pipeline) }

        it 'does not expose parser errors' do
          expect(subject[:status]).to eq(:parsed)
        end
      end
    end
  end
end
