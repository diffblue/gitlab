# frozen_string_literal: true

require "spec_helper"

RSpec.describe ::Gitlab::LicenseScanning::SbomScanner, feature_category: :software_composition_analysis do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:ref) { "license_scanning_example" }

  subject(:scanner) { described_class.new(project, pipeline) }

  before do
    stub_licensed_features(license_scanning: true)
  end

  describe ".latest_pipeline" do
    subject(:latest_pipeline) { described_class.latest_pipeline(project, ref) }

    context 'when the pipeline contains an sbom report' do
      let_it_be(:pipeline_with_ref) do
        create(:ee_ci_pipeline, :with_cyclonedx_report, project: project, ref: ref)
      end

      subject(:latest_pipeline) { described_class.latest_pipeline(project, ref) }

      it "returns the latest pipeline with a report for the specified ref" do
        expect(latest_pipeline).to eq(pipeline_with_ref)
      end
    end

    context 'when the pipeline does not contain an sbom report' do
      let_it_be(:pipeline) { create(:ee_ci_pipeline, :with_metrics_report, project: project) }

      it "returns nil" do
        expect(described_class.latest_pipeline(project, project.default_branch)).to be_nil
      end
    end
  end

  describe "#report" do
    subject(:report) { scanner.report }

    context "when the pipeline is nil" do
      let_it_be(:pipeline) { nil }

      it { is_expected.to be_empty }
    end

    context "when the pipeline is not nil" do
      context "when the pipeline contains an sbom report" do
        let_it_be(:pipeline) { create(:ee_ci_pipeline, :with_cyclonedx_report, project: project) }

        before_all do
          components_to_create_in_db = [
            Hashie::Mash.new(name: "github.com/astaxie/beego", purl_type: "golang", version: "v1.10.0"),
            Hashie::Mash.new(name: "acorn", purl_type: "npm", version: "5.7.3"),
            Hashie::Mash.new(name: "acorn", purl_type: "npm", version: "6.4.0"),
            Hashie::Mash.new(name: "json-schema", purl_type: "npm", version: "0.2.3"),
            Hashie::Mash.new(name: "org.apache.logging.log4j/log4j-core", purl_type: "maven", version: "2.6.1"),
            Hashie::Mash.new(name: "activesupport", purl_type: "gem", version: "5.1.4"),
            Hashie::Mash.new(name: "yargs-parser", purl_type: "npm", version: "9.0.2")
          ]

          components_to_create_in_db.each do |component|
            create(:pm_package_version_license, :with_all_relations, name: component.name,
              purl_type: component.purl_type, version: component.version, license_name: "OLDAP-2.1")
            create(:pm_package_version_license, :with_all_relations, name: component.name,
              purl_type: component.purl_type, version: component.version, license_name: "BSD")
          end
        end

        it 'returns the expected licenses' do
          expect(report.licenses).to match_array([
            have_attributes(id: "BSD-4-Clause", name: "BSD"),
            have_attributes(id: "OLDAP-2.1", name: "OLDAP-2.1"),
            have_attributes(id: nil, name: "unknown")
          ])
        end

        it 'returns the expected dependencies for known licenses' do
          bsd_license = report.licenses.find { |license| license.name == "BSD" }

          expect(bsd_license.dependencies).to match_array([
            have_attributes(name: "github.com/astaxie/beego", version: "v1.10.0"),
            have_attributes(name: "acorn", version: "5.7.3"),
            have_attributes(name: "acorn", version: "6.4.0"),
            have_attributes(name: "json-schema", version: "0.2.3"),
            have_attributes(name: "org.apache.logging.log4j/log4j-core", version: "2.6.1"),
            have_attributes(name: "activesupport", version: "5.1.4"),
            have_attributes(name: "yargs-parser", version: "9.0.2")
          ])
        end

        it 'returns the expected dependencies for unknown licenses' do
          unknown_license = report.licenses.find { |license| license.name == "unknown" }

          expect(unknown_license.dependencies.length).to be(434)

          expect(unknown_license.dependencies).to include(
            have_attributes(name: "byebug", version: "10.0.0"),
            have_attributes(name: "rspec-core", version: "3.7.1"),
            have_attributes(name: "yargs-parser", version: "8.1.0")
          )
        end
      end

      context "when the pipeline does not contain an sbom report" do
        let_it_be(:pipeline) { create(:ee_ci_pipeline, :with_license_scanning_report, project: project) }

        it { is_expected.to be_empty }
      end
    end
  end

  describe "#has_data?" do
    subject { scanner.has_data? }

    context "when the pipeline has an sbom report" do
      let_it_be(:pipeline) { create(:ee_ci_pipeline, :with_cyclonedx_report, project: project) }

      it { is_expected.to be_truthy }
    end

    context 'when the pipeline does not have an sbom report' do
      let_it_be(:pipeline) { create(:ee_ci_pipeline, :with_license_scanning_report, project: project) }

      it { is_expected.to be_falsy }
    end

    context "when the pipeline is nil" do
      let_it_be(:pipeline) { nil }

      it { is_expected.to be_falsy }
    end
  end

  describe "#results_available?" do
    subject { scanner.results_available? }

    context "when the pipeline is nil" do
      let_it_be(:pipeline) { nil }

      it { is_expected.to be_falsy }
    end

    context "when the pipeline is not nil" do
      context "and the pipeline has an sbom report" do
        let_it_be(:pipeline) { create(:ee_ci_pipeline, :with_cyclonedx_report, project: project) }

        it { is_expected.to be_truthy }

        context "and the pipeline is running" do
          let_it_be(:pipeline) { create(:ee_ci_pipeline, :running, project: project) }
          let_it_be(:build) do
            create(:ci_build, job_artifacts: [create(:ee_ci_job_artifact, :cyclonedx)], pipeline: pipeline)
          end

          context "and the mr_show_reports_immediately feature flag is false" do
            before do
              stub_feature_flags(mr_show_reports_immediately: false)
            end

            it { is_expected.to be_falsy }
          end

          context "and the mr_show_reports_immediately feature flag is true" do
            it { is_expected.to be_truthy }
          end
        end
      end

      context "when the pipeline does not have an sbom report" do
        let_it_be(:pipeline) { create(:ee_ci_pipeline, :with_license_scanning_report, project: project) }

        it { is_expected.to be_falsy }
      end
    end
  end

  describe "#latest_build_for_default_branch" do
    subject(:ci_build) { described_class.new(project, pipeline).latest_build_for_default_branch }

    context "when project has sbom generation jobs" do
      let_it_be(:pipeline) do
        create(:ee_ci_pipeline, :with_cyclonedx_report, project: project, ref: ref)
      end

      let_it_be(:default_branch_pipeline) do
        create(:ee_ci_pipeline, :with_cyclonedx_report, project: project, ref: project.default_branch)
      end

      it "returns build for default branch" do
        expect(ci_build.pipeline).to eql(default_branch_pipeline)
      end
    end

    context "when project has no sbom generation jobs" do
      let_it_be(:pipeline) do
        create(:ee_ci_pipeline, :with_metrics_report, project: project, ref: project.default_branch)
      end

      it "returns a nil result" do
        expect(ci_build).to be_nil
      end
    end
  end
end
