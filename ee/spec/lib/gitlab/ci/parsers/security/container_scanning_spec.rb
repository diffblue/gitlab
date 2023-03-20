# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Parsers::Security::ContainerScanning do
  let(:project) { create(:project, :repository) }
  let(:current_branch) { project.default_branch }
  let(:pipeline) { create(:ci_pipeline, ref: current_branch, project: project) }
  let(:job) { create(:ci_build, pipeline: pipeline) }
  let(:artifact) { create(:ee_ci_job_artifact, :container_scanning, job: job) }
  let(:report) { Gitlab::Ci::Reports::Security::Report.new(artifact.file_type, pipeline, 2.weeks.ago) }
  let(:image) { 'registry.gitlab.com/gitlab-org/security-products/dast/webgoat-8.0@sha256:bc09fe2e0721dfaeee79364115aeedf2174cce0947b9ae5fe7c33312ee019a4e' }
  let(:default_branch_image) { 'registry.gitlab.com/gitlab-org/security-products/dast/webgoat-8.0:latest' }

  shared_examples 'report' do
    it "parses all identifiers and findings for unapproved vulnerabilities" do
      expect(report.findings.length).to eq(8)
      expect(report.identifiers.length).to eq(8)
      expect(report.scanners).to include("trivy")
      expect(report.scanners.length).to eq(1)
    end

    it 'generates expected location', :aggregate_failures do
      location = report.findings.first.location

      expect(location).to be_a(::Gitlab::Ci::Reports::Security::Locations::ContainerScanning)
      expect(location).to have_attributes(
        image: image,
        operating_system: 'debian:9',
        package_name: 'glibc',
        package_version: '2.24-11+deb9u3'
      )
      expect(location.default_branch_image_validator).to be_a(Gitlab::Ci::Parsers::Security::Validators::DefaultBranchImageValidator)
    end

    it "generates expected metadata_version" do
      expect(report.findings.first.metadata_version).to eq('15.0.4')
    end

    it "adds report image's name to raw_metadata" do
      expect(Gitlab::Json.parse(report.findings.first.raw_metadata).dig('location', 'image')).to eq(image)
    end
  end

  describe '#parse!' do
    before do
      artifact.each_blob { |blob| described_class.parse!(blob, report) }
    end

    it_behaves_like 'report'

    context 'when on default branch' do
      let(:current_branch) { project.default_branch }

      it 'does not include default_branch_image in location' do
        location = report.findings.first.location

        expect(location).to be_a(::Gitlab::Ci::Reports::Security::Locations::ContainerScanning)
        expect(location).to have_attributes(
          default_branch_image: nil
        )
      end
    end

    context 'when not on default branch' do
      let(:current_branch) { 'not-default' }

      it 'includes default_branch_image in location' do
        location = report.findings.first.location

        expect(location).to be_a(::Gitlab::Ci::Reports::Security::Locations::ContainerScanning)
        expect(location).to have_attributes(
          default_branch_image: default_branch_image
        )
      end
    end
  end
end
