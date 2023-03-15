# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::ReportFetchService, feature_category: :vulnerability_management do
  let_it_be(:project) { create(:project) }

  let(:service) { described_class.new(project, artifact) }
  let(:artifact) { ::Ci::JobArtifact.of_report_type(:dependency_list) }

  describe '#pipeline' do
    subject { service.pipeline }

    context 'with found pipeline' do
      let!(:pipeline1) { create(:ee_ci_pipeline, :with_dependency_list_report, project: project) }
      let!(:pipeline2) { create(:ee_ci_pipeline, :with_dependency_list_report, project: project) }

      it { is_expected.to eq(pipeline2) }
    end

    context 'without any pipelines' do
      it { is_expected.to be_nil }
    end
  end

  describe '#build' do
    subject { service.build }

    context 'with right artifacts' do
      let!(:pipeline) { create(:ee_ci_pipeline, :with_dependency_list_report, project: project) }
      let(:build) { pipeline.builds.last }

      it { is_expected.to eq(build) }
    end

    context 'without right kind of artifacts' do
      let!(:pipeline) { create(:ee_ci_pipeline, :with_sast_report, project: project) }

      it { is_expected.to be_nil }
    end

    context 'without found pipeline' do
      it { is_expected.to be_nil }
    end
  end

  describe '#able_to_fetch?' do
    subject { service.able_to_fetch? }

    before do
      allow(service).to receive(:build).and_return(build)
    end

    context 'with successful build' do
      let(:build) { create(:ci_build, :success) }

      it { is_expected.to be_truthy }
    end

    context 'with failed build' do
      let(:build) { create(:ci_build, :failed) }

      it { is_expected.to be_falsey }
    end

    context 'without build' do
      let(:build) { nil }

      it { is_expected.to be_falsey }
    end
  end
end
