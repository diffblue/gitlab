# frozen_string_literal: true

require "spec_helper"

RSpec.describe SCA::LicenseCompliance, feature_category: :software_composition_analysis do
  let(:license_compliance) { described_class.new(project, pipeline) }

  let_it_be(:project) { create(:project, :repository, :private) }

  let(:mit) { create(:software_license, :mit) }
  let(:other_license) { create(:software_license, name: "SOFTWARE-LICENSE", spdx_identifier: "Other-Id") }

  before do
    stub_licensed_features(license_scanning: true)
  end

  describe "#policies" do
    context 'when license policies are configured with scan result policies' do
      subject(:policies) { license_compliance.policies }

      let(:pipeline) { create(:ci_pipeline, :success, project: project, builds: []) }

      let(:license_check_and_scan_result_policies) do
        [
          { id: 'MIT', name: 'MIT', classification: 'allowed', scan_result_policy: false },
          { id: 'AML', name: 'Apple MIT License', classification: 'denied', scan_result_policy: false },
          { id: 'MS-PL', name: 'Microsoft Public License', classification: 'denied', scan_result_policy: true },
          { id: 'Apache-2.0', name: 'Apache-2.0 License', classification: 'allowed', scan_result_policy: true }
        ]
      end

      let(:denied_scan_result_policies) do
        [
          { id: 'MIT', name: 'MIT', classification: 'allowed', scan_result_policy: false },
          { id: 'AML', name: 'Apple MIT License', classification: 'denied', scan_result_policy: false },
          { id: 'MS-PL', name: 'Microsoft Public License', classification: 'denied', scan_result_policy: true }
        ]
      end

      let(:only_license_check_policies) do
        [
          { id: 'MIT', name: 'MIT', classification: 'allowed', scan_result_policy: false },
          { id: 'AML', name: 'Apple MIT License', classification: 'denied', scan_result_policy: false }
        ]
      end

      let(:only_scan_result_policies) do
        [
          { id: 'Apache-2.0', name: 'Apache-2.0 License', classification: 'allowed', scan_result_policy: true },
          { id: 'MS-PL', name: 'Microsoft Public License', classification: 'denied', scan_result_policy: true }
        ]
      end

      let(:license_map) do
        {
          'MIT' => create(:software_license, name: 'MIT', spdx_identifier: 'MIT'),
          'AML' => create(:software_license, name: 'Apple MIT License', spdx_identifier: 'AML'),
          'MS-PL' => create(:software_license, name: 'Microsoft Public License', spdx_identifier: 'MS-PL'),
          'Apache-2.0' => create(:software_license, name: 'Apache-2.0 License', spdx_identifier: 'Apache-2.0'),
          'GPL-3-Clause' => create(:software_license, name: 'GPL-3-Clause', spdx_identifier: 'GPL-3-Clause'),
          'unknown' => create(:software_license, name: 'unknown', spdx_identifier: 'unknown')
        }
      end

      using RSpec::Parameterized::TableSyntax

      where(:input, :result) do
        ref(:license_check_and_scan_result_policies) | %w[denied allowed denied allowed denied denied]
        ref(:denied_scan_result_policies) | %w[denied unclassified unclassified allowed denied unclassified]
        ref(:only_license_check_policies) | %w[denied unclassified unclassified allowed unclassified unclassified]
        ref(:only_scan_result_policies) | %w[denied allowed denied denied denied denied]
      end

      with_them do
        let(:report) { create(:ci_reports_license_scanning_report) }

        before do
          report.add_license(id: 'MIT', name: 'MIT')
          report.add_license(id: 'AML', name: 'Apple MIT License')
          report.add_license(id: 'MS-PL', name: 'Microsoft Public License')
          report.add_license(id: 'Apache-2.0', name: 'Apache-2.0 License')
          report.add_license(id: 'GPL-3-Clause', name: 'GPL-3-Clause')
          report.add_license(id: 'unknown', name: 'unknown')

          allow(license_compliance).to receive(:license_scanning_report).and_return(report)

          input.each do |policy|
            scan_result_policy_read = policy[:scan_result_policy] ? create(:scan_result_policy_read, match_on_inclusion: policy[:classification] == 'denied') : nil
            create(:software_license_policy, policy[:classification],
              project: project,
              software_license: license_map[policy[:id]],
              scan_result_policy_read: scan_result_policy_read
            )
          end
        end

        it 'sets classification based on policies' do
          expect(policies.map(&:classification)).to eq(result)
        end
      end
    end

    context "when the license_scanning_sbom_scanner feature flag is disabled" do
      subject(:policies) { license_compliance.policies }

      before do
        stub_feature_flags(license_scanning_sbom_scanner: false)
      end

      context "when a pipeline has not been run for this project" do
        let(:pipeline) { nil }

        it { expect(policies.count).to be_zero }

        context "when the project has policies configured" do
          let!(:mit_policy) { create(:software_license_policy, :denied, software_license: mit, project: project) }

          it "includes an a policy for a classified license that was not detected in the scan report" do
            expect(policies.count).to eq(1)
            expect(policies[0].id).to eq(mit_policy.id)
            expect(policies[0].name).to eq(mit.name)
            expect(policies[0].url).to be_nil
            expect(policies[0].classification).to eq("denied")
            expect(policies[0].spdx_identifier).to eq(mit.spdx_identifier)
          end
        end
      end

      context "when a pipeline has run" do
        let(:pipeline) { create(:ci_pipeline, :success, project: project, builds: builds) }
        let(:builds) { [] }

        context "when a license scan job is not configured" do
          let(:builds) { [create(:ci_build, :success)] }

          it { expect(policies).to be_empty }
        end

        context "when the license scan job has not finished" do
          let(:builds) { [create(:ci_build, :running, job_artifacts: [artifact])] }
          let(:artifact) { create(:ci_job_artifact, file_type: :license_scanning, file_format: :raw) }

          it { expect(policies).to be_empty }
        end

        context "when the license scan produces a poorly formatted report" do
          let(:builds) { [create(:ee_ci_build, :running, :corrupted_license_scanning_report)] }

          it { expect(policies).to be_empty }
        end

        context "when the dependency scan produces a poorly formatted report" do
          let(:builds) do
            [
              create(:ee_ci_build, :success, :license_scan_v2_1),
              create(:ee_ci_build, :success, :corrupted_dependency_scanning_report)
            ]
          end

          it { expect(policies.map(&:spdx_identifier)).to contain_exactly("BSD-3-Clause", "MIT", nil) }
        end

        context "when a pipeline has successfully produced a v2.0 license scan report" do
          let(:builds) { [create(:ee_ci_build, :success, :license_scan_v2)] }
          let!(:mit_policy) { create(:software_license_policy, :denied, software_license: mit, project: project) }
          let!(:other_license_policy) { create(:software_license_policy, :allowed, software_license: other_license, project: project) }

          it "includes a policy for each detected license and classified license" do
            expect(policies.count).to eq(4)
          end

          it 'includes a policy for a detected license that is unclassified' do
            expect(policies[0].id).to be_nil
            expect(policies[0].name).to eq("BSD 3-Clause \"New\" or \"Revised\" License")
            expect(policies[0].url).to eq("http://spdx.org/licenses/BSD-3-Clause.json")
            expect(policies[0].classification).to eq("unclassified")
            expect(policies[0].spdx_identifier).to eq("BSD-3-Clause")
          end

          it 'includes a policy for a classified license that was also detected in the scan report' do
            expect(policies[1].id).to eq(mit_policy.id)
            expect(policies[1].name).to eq(mit.name)
            expect(policies[1].url).to eq("http://spdx.org/licenses/MIT.json")
            expect(policies[1].classification).to eq("denied")
            expect(policies[1].spdx_identifier).to eq("MIT")
          end

          it 'includes a policy for a classified license that was not detected in the scan report' do
            expect(policies[2].id).to eq(other_license_policy.id)
            expect(policies[2].name).to eq(other_license.name)
            expect(policies[2].url).to be_blank
            expect(policies[2].classification).to eq("allowed")
            expect(policies[2].spdx_identifier).to eq(other_license.spdx_identifier)
          end

          it 'includes a policy for an unclassified and unknown license that was detected in the scan report' do
            expect(policies[3].id).to be_nil
            expect(policies[3].name).to eq("unknown")
            expect(policies[3].url).to be_blank
            expect(policies[3].classification).to eq("unclassified")
            expect(policies[3].spdx_identifier).to be_nil
          end
        end

        context "when a pipeline has successfully produced a v2.1 license scan report" do
          let(:builds) { [create(:ee_ci_build, :success, :license_scan_v2_1)] }
          let!(:mit_policy) { create(:software_license_policy, :denied, software_license: mit, project: project) }
          let!(:other_license_policy) { create(:software_license_policy, :allowed, software_license: other_license, project: project) }

          it "includes a policy for each detected license and classified license" do
            expect(policies.count).to eq(4)
          end

          it 'includes a policy for a detected license that is unclassified' do
            expect(policies[0].id).to be_nil
            expect(policies[0].name).to eq("BSD 3-Clause \"New\" or \"Revised\" License")
            expect(policies[0].url).to eq("https://opensource.org/licenses/BSD-3-Clause")
            expect(policies[0].classification).to eq("unclassified")
            expect(policies[0].spdx_identifier).to eq("BSD-3-Clause")
          end

          it 'includes a policy for a classified license that was also detected in the scan report' do
            expect(policies[1].id).to eq(mit_policy.id)
            expect(policies[1].name).to eq(mit.name)
            expect(policies[1].url).to eq("https://opensource.org/licenses/MIT")
            expect(policies[1].classification).to eq("denied")
            expect(policies[1].spdx_identifier).to eq("MIT")
          end

          it 'includes a policy for a classified license that was not detected in the scan report' do
            expect(policies[2].id).to eq(other_license_policy.id)
            expect(policies[2].name).to eq(other_license.name)
            expect(policies[2].url).to be_blank
            expect(policies[2].classification).to eq("allowed")
            expect(policies[2].spdx_identifier).to eq(other_license.spdx_identifier)
          end

          it 'includes a policy for an unclassified and unknown license that was detected in the scan report' do
            expect(policies[3].id).to be_nil
            expect(policies[3].name).to eq("unknown")
            expect(policies[3].url).to be_blank
            expect(policies[3].classification).to eq("unclassified")
            expect(policies[3].spdx_identifier).to be_nil
          end
        end

        context "when a pipeline has successfully produced a v1.1 license scan report" do
          let(:builds) { [create(:ee_ci_build, :license_scan_v1_1, :success)] }
          let!(:mit_policy) { create(:software_license_policy, :denied, software_license: mit, project: project) }
          let!(:other_license_policy) { create(:software_license_policy, :allowed, software_license: other_license, project: project) }

          it 'includes a policy for an unclassified license detected in the scan report' do
            expect(policies[0].id).to be_nil
            expect(policies[0].name).to eq("BSD")
            expect(policies[0].url).to eq("http://spdx.org/licenses/BSD-4-Clause.json")
            expect(policies[0].classification).to eq("unclassified")
            expect(policies[0].spdx_identifier).to eq("BSD-4-Clause")
          end

          it 'includes a policy for a denied license found in the scan report' do
            expect(policies[1].id).to eq(mit_policy.id)
            expect(policies[1].name).to eq(mit.name)
            expect(policies[1].url).to eq("http://opensource.org/licenses/mit-license")
            expect(policies[1].classification).to eq("denied")
            expect(policies[1].spdx_identifier).to eq("MIT")
          end

          it 'includes a policy for an allowed license NOT found in the scan report' do
            expect(policies[2].id).to eq(other_license_policy.id)
            expect(policies[2].name).to eq(other_license.name)
            expect(policies[2].url).to be_blank
            expect(policies[2].classification).to eq("allowed")
            expect(policies[2].spdx_identifier).to eq(other_license.spdx_identifier)
          end

          it 'includes a policy for an unclassified and unknown license found in the scan report' do
            expect(policies[3].id).to be_nil
            expect(policies[3].name).to eq("unknown")
            expect(policies[3].url).to be_blank
            expect(policies[3].classification).to eq("unclassified")
            expect(policies[3].spdx_identifier).to be_nil
          end
        end
      end
    end

    context "when the license_scanning_sbom_scanner feature flag is enabled" do
      subject(:policies) { license_compliance.policies }

      before do
        create(:pm_package_version_license, :with_all_relations, name: "activesupport", purl_type: "gem", version: "5.1.4", license_name: "MIT")
        create(:pm_package_version_license, :with_all_relations, name: "github.com/sirupsen/logrus", purl_type: "golang", version: "v1.4.2", license_name: "MIT")
        create(:pm_package_version_license, :with_all_relations, name: "github.com/sirupsen/logrus", purl_type: "golang", version: "v1.4.2", license_name: "BSD-3-Clause")
        create(:pm_package_version_license, :with_all_relations, name: "org.apache.logging.log4j/log4j-api", purl_type: "maven", version: "2.6.1", license_name: "BSD-3-Clause")
      end

      context "when a pipeline has not been run for this project" do
        let(:pipeline) { nil }

        it { expect(policies.count).to be_zero }

        context "when the project has policies configured" do
          let!(:mit_policy) { create(:software_license_policy, :denied, software_license: mit, project: project) }

          it "includes an a policy for a classified license that was not detected in the scan report" do
            expect(policies.count).to eq(1)
            expect(policies[0].id).to eq(mit_policy.id)
            expect(policies[0].name).to eq(mit.name)
            expect(policies[0].url).to be_blank
            expect(policies[0].classification).to eq("denied")
            expect(policies[0].spdx_identifier).to eq(mit.spdx_identifier)
          end
        end
      end

      context "when a pipeline has run" do
        let(:pipeline) { create(:ci_pipeline, :success, project: project, builds: builds) }
        let(:builds) { [] }

        context "when a license scan job is not configured" do
          let(:builds) { [create(:ci_build, :success)] }

          it { expect(policies).to be_empty }
        end

        context "when the license scan job has not finished" do
          let(:builds) { [create(:ee_ci_build, :running, job_artifacts: [artifact])] }
          # Creating the artifact manually skips the artifact upload step and simulates
          # a pending artifact upload.
          let(:artifact) { create(:ee_ci_job_artifact, file_type: :cyclonedx, file_format: :gzip) }

          it { expect(policies).to be_empty }
        end

        context "when a pipeline has successfully produced a cyclonedx report" do
          let(:builds) { [create(:ee_ci_build, :cyclonedx)] }
          let!(:mit_policy) { create(:software_license_policy, :denied, software_license: mit, project: project) }
          let!(:other_license_policy) { create(:software_license_policy, :allowed, software_license: other_license, project: project) }

          it "includes a policy for each detected license and classified license" do
            expect(policies.count).to eq(4)
          end

          it 'includes a policy for a detected license that is unclassified' do
            expect(policies[0].id).to be_nil
            expect(policies[0].name).to eq("BSD-3-Clause")
            expect(policies[0].url).to eq("https://spdx.org/licenses/BSD-3-Clause.html")
            expect(policies[0].classification).to eq("unclassified")
            expect(policies[0].spdx_identifier).to eq("BSD-3-Clause")
          end

          it 'includes a policy for a classified license that was also detected in the scan report' do
            expect(policies[1].id).to eq(mit_policy.id)
            expect(policies[1].name).to eq(mit.name)
            expect(policies[1].url).to eq("https://spdx.org/licenses/MIT.html")
            expect(policies[1].classification).to eq("denied")
            expect(policies[1].spdx_identifier).to eq("MIT")
          end

          it 'includes a policy for a classified license that was not detected in the scan report' do
            expect(policies[2].id).to eq(other_license_policy.id)
            expect(policies[2].name).to eq(other_license.name)
            expect(policies[2].url).to be_blank
            expect(policies[2].classification).to eq("allowed")
            expect(policies[2].spdx_identifier).to eq(other_license.spdx_identifier)
          end

          it 'includes a policy for an unclassified and unknown license that was detected in the scan report' do
            expect(policies[3].id).to be_nil
            expect(policies[3].name).to eq("unknown")
            expect(policies[3].url).to be_blank
            expect(policies[3].classification).to eq("unclassified")
            expect(policies[3].spdx_identifier).to be_nil
          end
        end
      end
    end
  end

  describe "#find_policies" do
    def assert_matches(item, expected = {})
      actual = expected.keys.index_with do |attribute|
        item.public_send(attribute)
      end
      expect(actual).to eql(expected)
    end

    context "when the license_scanning_sbom_scanner feature flag is disabled" do
      let!(:pipeline) { create(:ci_pipeline, :success, project: project, builds: [create(:ee_ci_build, :success, :license_scan_v2_1)]) }
      let!(:mit_policy) { create(:software_license_policy, :denied, software_license: mit, project: project) }
      let!(:other_license_policy) { create(:software_license_policy, :allowed, software_license: other_license, project: project) }

      before do
        stub_feature_flags(license_scanning_sbom_scanner: false)
      end

      it 'records an onboarding progress action for license scanning' do
        expect(Onboarding::Progress).to receive(:register).with(pipeline.project.root_namespace, :license_scanning_run).and_call_original

        license_compliance.find_policies
      end

      context 'when pipeline is not present' do
        let!(:pipeline) { nil }

        it 'records an onboarding progress action for license scanning' do
          expect(Onboarding::Progress).not_to receive(:register).with(anything)

          license_compliance.find_policies
        end
      end

      context 'when searching for policies for licenses that were detected in a scan report' do
        let(:results) { license_compliance.find_policies(detected_only: true) }

        it 'only includes licenses that appear in the latest license scan report' do
          expect(results.count).to eq(3)
        end

        it 'includes a policy for an unclassified and known license that was detected in the scan report' do
          assert_matches(
            results[0],
            id: nil,
            name: 'BSD 3-Clause "New" or "Revised" License',
            url: "https://opensource.org/licenses/BSD-3-Clause",
            classification: "unclassified",
            spdx_identifier: "BSD-3-Clause"
          )
        end

        it 'includes an entry for a denied license found in the scan report' do
          assert_matches(
            results[1],
            id: mit_policy.id,
            name: mit.name,
            url: "https://opensource.org/licenses/MIT",
            classification: "denied",
            spdx_identifier: "MIT"
          )
        end

        it 'includes an entry for an allowed license found in the scan report' do
          assert_matches(
            results[2],
            id: nil,
            name: 'unknown',
            url: nil,
            classification: 'unclassified',
            spdx_identifier: nil
          )
        end

        context "with denied license without spdx identifier" do
          let!(:pipeline) { create(:ci_pipeline, :success, project: project, builds: [create(:ee_ci_build, :success, :license_scanning_custom_license)]) }
          let(:custom_license) { create(:software_license, :user_entered, name: "foO licensE") }
          let!(:custom_license_policy) { create(:software_license_policy, :denied, software_license: custom_license, project: project) }

          let(:results) { license_compliance.find_policies(detected_only: true) }

          it 'contains denied license' do
            expect(results.count).to eq(3)
          end
        end
      end

      context "when searching for policies with a specific classification" do
        let(:results) { license_compliance.find_policies(classification: ['allowed']) }

        it 'includes an entry for each `allowed` licensed' do
          expect(results.count).to eq(1)
          assert_matches(
            results[0],
            id: other_license_policy.id,
            name: other_license_policy.software_license.name,
            url: nil,
            classification: 'allowed',
            spdx_identifier: other_license_policy.software_license.spdx_identifier
          )
        end
      end

      context "when searching for policies by multiple classifications" do
        let(:results) { license_compliance.find_policies(classification: %w[allowed denied]) }

        it 'includes an entry for each `allowed` and `denied` licensed' do
          expect(results.count).to eq(2)
          assert_matches(
            results[0],
            id: mit_policy.id,
            name: mit_policy.software_license.name,
            url: 'https://opensource.org/licenses/MIT',
            classification: "denied",
            spdx_identifier: mit_policy.software_license.spdx_identifier
          )
          assert_matches(
            results[1],
            id: other_license_policy.id,
            name: other_license_policy.software_license.name,
            url: nil,
            classification: "allowed",
            spdx_identifier: other_license_policy.software_license.spdx_identifier
          )
        end
      end

      context "when searching for detected policies matching a classification" do
        let(:results) { license_compliance.find_policies(detected_only: true, classification: %w[allowed denied]) }

        it 'includes an entry for each entry that was detected in the report and matches a classification' do
          expect(results.count).to eq(1)
          assert_matches(
            results[0],
            id: mit_policy.id,
            name: mit_policy.software_license.name,
            url: 'https://opensource.org/licenses/MIT',
            classification: "denied",
            spdx_identifier: mit_policy.software_license.spdx_identifier
          )
        end
      end

      context 'when sorting policies' do
        let(:sorted_by_name_asc) { ['BSD 3-Clause "New" or "Revised" License', 'MIT', 'SOFTWARE-LICENSE', 'unknown'] }

        where(:attribute, :direction, :expected) do
          sorted_by_name_asc = ['BSD 3-Clause "New" or "Revised" License', 'MIT', 'SOFTWARE-LICENSE', 'unknown']
          sorted_by_classification_asc = ['SOFTWARE-LICENSE', 'BSD 3-Clause "New" or "Revised" License', 'unknown', 'MIT']
          [
            [:classification, :asc, sorted_by_classification_asc],
            [:classification, :desc, sorted_by_classification_asc.reverse],
            [:name, :desc, sorted_by_name_asc.reverse],
            [:invalid, :asc, sorted_by_name_asc],
            [:name, :invalid, sorted_by_name_asc],
            [:name, nil, sorted_by_name_asc],
            [nil, :asc, sorted_by_name_asc],
            [nil, nil, sorted_by_name_asc]
          ]
        end

        with_them do
          let(:results) { license_compliance.find_policies(sort: { by: attribute, direction: direction }) }

          it { expect(results.map(&:name)).to eq(expected) }
        end

        context 'when using the default sort options' do
          it { expect(license_compliance.find_policies.map(&:name)).to eq(sorted_by_name_asc) }
        end

        context 'when `nil` sort options are provided' do
          it { expect(license_compliance.find_policies(sort: nil).map(&:name)).to eq(sorted_by_name_asc) }
        end
      end
    end

    context "when the license_scanning_sbom_scanner feature flag is enabled" do
      let!(:pipeline) { create(:ee_ci_pipeline, :with_cyclonedx_report, project: project) }
      let!(:mit_policy) { create(:software_license_policy, :denied, software_license: mit, project: project) }
      let(:other_license) { create(:software_license, name: 'BSD-3-Clause', spdx_identifier: "BSD-3-Clause") }
      let!(:other_license_policy) { create(:software_license_policy, :allowed, software_license: other_license, project: project) }

      before do
        create(:pm_package_version_license, :with_all_relations, name: "activesupport", purl_type: "gem", version: "5.1.4", license_name: "MIT")
        create(:pm_package_version_license, :with_all_relations, name: "github.com/sirupsen/logrus", purl_type: "golang", version: "v1.4.2", license_name: "MIT")
        create(:pm_package_version_license, :with_all_relations, name: "github.com/sirupsen/logrus", purl_type: "golang", version: "v1.4.2", license_name: "BSD-3-Clause")
        create(:pm_package_version_license, :with_all_relations, name: "org.apache.logging.log4j/log4j-api", purl_type: "maven", version: "2.6.1", license_name: "BSD-3-Clause")
        create(:pm_package_version_license, :with_all_relations, name: "nokogiri", purl_type: "gem", version: "1.8.0", license_name: "CUSTOM_DENIED_LICENSE")
      end

      it 'records an onboarding progress action for license scanning' do
        expect(Onboarding::Progress).to receive(:register).with(pipeline.project.root_namespace, :license_scanning_run).and_call_original

        license_compliance.find_policies
      end

      context 'when pipeline is not present' do
        let!(:pipeline) { nil }

        it 'records an onboarding progress action for license scanning' do
          expect(Onboarding::Progress).not_to receive(:register).with(anything)

          license_compliance.find_policies
        end
      end

      context 'when searching for policies for licenses that were detected in a scan report' do
        let(:results) { license_compliance.find_policies(detected_only: true) }

        it 'only includes licenses that appear in the latest license scan report' do
          expect(results.count).to eq(4)
        end

        it 'includes a policy for an allowed known license that was detected in the scan report' do
          assert_matches(
            results[0],
            id: other_license_policy.id,
            name: other_license.name,
            url: "https://spdx.org/licenses/BSD-3-Clause.html",
            classification: "allowed",
            spdx_identifier: "BSD-3-Clause"
          )
        end

        it 'includes an entry for an unclassified custom license found in the scan report' do
          assert_matches(
            results[1],
            id: nil,
            name: "CUSTOM_DENIED_LICENSE",
            url: "https://spdx.org/licenses/CUSTOM_DENIED_LICENSE.html",
            classification: "unclassified",
            spdx_identifier: "CUSTOM_DENIED_LICENSE"
          )
        end

        it 'includes an entry for a denied license found in the scan report' do
          assert_matches(
            results[2],
            id: mit_policy.id,
            name: mit.name,
            url: "https://spdx.org/licenses/MIT.html",
            classification: "denied",
            spdx_identifier: "MIT"
          )
        end

        it 'includes an entry for an unclassified unknown license found in the scan report' do
          assert_matches(
            results[3],
            id: nil,
            name: 'unknown',
            url: nil,
            classification: 'unclassified',
            spdx_identifier: nil
          )
        end

        context "with denied license without spdx identifier" do
          let!(:pipeline) { create(:ee_ci_pipeline, :with_cyclonedx_report, project: project) }
          let(:custom_license) { create(:software_license, :user_entered, name: "CUSTOM_DENIED_LICENSE") }
          let!(:custom_license_policy) { create(:software_license_policy, :denied, software_license: custom_license, project: project) }

          let(:results) { license_compliance.find_policies(detected_only: true) }

          it 'contains denied license' do
            expect(results.count).to eq(4)
          end
        end
      end

      context "when searching for policies with a specific classification" do
        let(:results) { license_compliance.find_policies(classification: ['allowed']) }

        it 'includes an entry for each `allowed` licensed' do
          expect(results.count).to eq(1)
          assert_matches(
            results[0],
            id: other_license_policy.id,
            name: other_license_policy.software_license.name,
            url: "https://spdx.org/licenses/BSD-3-Clause.html",
            classification: 'allowed',
            spdx_identifier: other_license_policy.software_license.spdx_identifier
          )
        end
      end

      context "when searching for policies by multiple classifications" do
        let(:results) { license_compliance.find_policies(classification: %w[allowed denied]) }

        it 'includes an entry for each `allowed` and `denied` licensed' do
          expect(results.count).to eq(2)
          assert_matches(
            results[0],
            id: other_license_policy.id,
            name: other_license_policy.software_license.name,
            url: "https://spdx.org/licenses/BSD-3-Clause.html",
            classification: "allowed",
            spdx_identifier: other_license_policy.software_license.spdx_identifier
          )
          assert_matches(
            results[1],
            id: mit_policy.id,
            name: mit_policy.software_license.name,
            url: "https://spdx.org/licenses/MIT.html",
            classification: "denied",
            spdx_identifier: mit_policy.software_license.spdx_identifier
          )
        end
      end

      context "when searching for detected policies matching a classification" do
        let(:results) { license_compliance.find_policies(detected_only: true, classification: %w[allowed denied]) }

        it 'includes an entry for each entry that was detected in the report and matches a classification' do
          expect(results.count).to eq(2)
          assert_matches(
            results[0],
            id: other_license_policy.id,
            name: other_license_policy.software_license.name,
            url: "https://spdx.org/licenses/BSD-3-Clause.html",
            classification: "allowed",
            spdx_identifier: other_license_policy.software_license.spdx_identifier
          )
          assert_matches(
            results[1],
            id: mit_policy.id,
            name: mit_policy.software_license.name,
            url: "https://spdx.org/licenses/MIT.html",
            classification: "denied",
            spdx_identifier: mit_policy.software_license.spdx_identifier
          )
        end
      end

      context 'when sorting policies' do
        let(:sorted_by_name_asc) { ['BSD-3-Clause', 'CUSTOM_DENIED_LICENSE', 'MIT', 'unknown'] }

        where(:attribute, :direction, :expected) do
          sorted_by_name_asc = ['BSD-3-Clause', 'CUSTOM_DENIED_LICENSE', 'MIT', 'unknown']
          sorted_by_classification_asc = ['BSD-3-Clause', 'CUSTOM_DENIED_LICENSE', 'unknown', 'MIT']
          [
            [:classification, :asc, sorted_by_classification_asc],
            [:classification, :desc, sorted_by_classification_asc.reverse],
            [:name, :desc, sorted_by_name_asc.reverse],
            [:invalid, :asc, sorted_by_name_asc],
            [:name, :invalid, sorted_by_name_asc],
            [:name, nil, sorted_by_name_asc],
            [nil, :asc, sorted_by_name_asc],
            [nil, nil, sorted_by_name_asc]
          ]
        end

        with_them do
          let(:results) { license_compliance.find_policies(sort: { by: attribute, direction: direction }) }

          it { expect(results.map(&:name)).to eq(expected) }
        end

        context 'when using the default sort options' do
          it { expect(license_compliance.find_policies.map(&:name)).to eq(sorted_by_name_asc) }
        end

        context 'when `nil` sort options are provided' do
          it { expect(license_compliance.find_policies(sort: nil).map(&:name)).to eq(sorted_by_name_asc) }
        end
      end
    end
  end

  describe "#latest_build_for_default_branch" do
    subject { license_compliance.latest_build_for_default_branch }

    context "when the license_scanning_sbom_scanner feature flag is disabled" do
      let(:pipeline) { nil }
      let(:regular_build) { create(:ci_build, :success) }
      let(:license_scan_build) { create(:ee_ci_build, :license_scan_v2_1, :success) }

      before do
        stub_feature_flags(license_scanning_sbom_scanner: false)
      end

      context "when a pipeline has never been completed for the project" do
        let(:pipeline) { nil }

        it { is_expected.to be_nil }
      end

      context "when a pipeline has completed successfully and produced a license scan report" do
        let!(:pipeline) { create(:ci_pipeline, :success, project: project, builds: [regular_build, license_scan_build]) }

        it { is_expected.to eq(license_scan_build) }
      end

      context "when a pipeline has completed but does not contain a license scan report" do
        let!(:pipeline) { create(:ci_pipeline, :success, project: project, builds: [regular_build]) }

        it { is_expected.to be_nil }
      end
    end

    context "when the license_scanning_sbom_scanner feature flag is enabled" do
      let(:pipeline) { nil }
      let(:regular_build) { create(:ci_build, :success) }
      let(:license_scan_build) { create(:ee_ci_build, :cyclonedx, :success) }

      before do
        create(:pm_package_version_license, :with_all_relations, name: "activesupport", purl_type: "gem", version: "5.1.4", license_name: "MIT")
        create(:pm_package_version_license, :with_all_relations, name: "github.com/sirupsen/logrus", purl_type: "golang", version: "v1.4.2", license_name: "MIT")
        create(:pm_package_version_license, :with_all_relations, name: "github.com/sirupsen/logrus", purl_type: "golang", version: "v1.4.2", license_name: "BSD-3-Clause")
        create(:pm_package_version_license, :with_all_relations, name: "org.apache.logging.log4j/log4j-api", purl_type: "maven", version: "2.6.1", license_name: "BSD-3-Clause")
      end

      context "when a pipeline has never been completed for the project" do
        let(:pipeline) { nil }

        it { is_expected.to be_nil }
      end

      context "when a pipeline has completed successfully and produced a license scan report" do
        let!(:pipeline) { create(:ee_ci_pipeline, :success, project: project, builds: [regular_build, license_scan_build]) }

        it { is_expected.to eq(license_scan_build) }
      end

      context "when a pipeline has completed but does not contain a license scan report" do
        let!(:pipeline) { create(:ci_pipeline, :success, project: project, builds: [regular_build]) }

        it { is_expected.to be_nil }
      end
    end
  end

  describe "#diff_with" do
    context 'when license policies are configured with scan result policies' do
      subject(:diff) { license_compliance.diff_with(base_compliance) }

      let(:mit) { create(:software_license, name: 'MIT', spdx_identifier: 'MIT') }
      let(:aml) { create(:software_license, name: 'Apple MIT License', spdx_identifier: 'AML') }
      let(:mspl) { create(:software_license, name: 'Microsoft Public License', spdx_identifier: 'MS-PL') }
      let(:apache_2) { create(:software_license, name: 'Apache-2.0 License', spdx_identifier: 'Apache-2.0') }

      let(:pipeline) { create(:ci_pipeline, :success, project: project, builds: []) }
      let(:base_pipeline) { create(:ci_pipeline, :success, project: project) }
      let(:base_compliance) { project.license_compliance(base_pipeline) }

      let(:base_report) { create(:ci_reports_license_scanning_report) }
      let(:report) { create(:ci_reports_license_scanning_report) }

      let(:scan_result_policy_read_with_inclusion) { create(:scan_result_policy_read, match_on_inclusion: true) }
      let(:scan_result_policy_read_without_inclusion) { create(:scan_result_policy_read, match_on_inclusion: false) }

      context 'when base_report has new denied licenses' do
        before do
          report.add_license(id: 'MIT', name: 'MIT')
          base_report.add_license(id: 'MIT', name: 'MIT')
          base_report.add_license(id: 'AML', name: 'Apple MIT License')
          base_report.add_license(id: 'MS-PL', name: 'Microsoft Public License')

          allow(license_compliance).to receive(:license_scanning_report).and_return(report)
          allow(base_compliance).to receive(:license_scanning_report).and_return(base_report)

          create(:software_license_policy, :allowed,
            project: project,
            software_license: mit,
            scan_result_policy_read: scan_result_policy_read_without_inclusion
          )
          create(:software_license_policy, :denied,
            project: project,
            software_license: aml,
            scan_result_policy_read: scan_result_policy_read_with_inclusion
          )
        end

        it 'returns differences with denied status' do
          added = diff[:added]

          expect(added[0].spdx_identifier).to eq('AML')
          expect(added[0].classification).to eq('denied')
          expect(added[1].spdx_identifier).to eq('MS-PL')
          expect(added[1].classification).to eq('denied')
        end
      end
    end

    context "when the license_scanning_sbom_scanner feature flag is disabled" do
      before do
        stub_feature_flags(license_scanning_sbom_scanner: false)
      end

      context "when the head pipeline has not run" do
        subject(:diff) { license_compliance.diff_with(base_compliance) }

        let(:pipeline) { nil }

        let!(:base_compliance) { project.license_compliance(base_pipeline) }
        let!(:base_pipeline) { create(:ci_pipeline, :success, project: project, builds: [license_scan_build]) }
        let(:license_scan_build) { create(:ee_ci_build, :license_scan_v2_1, :success) }

        it "returns the differences in licenses introduced by the merge request" do
          expect(diff[:added]).to all(be_instance_of(::SCA::LicensePolicy))
          expect(diff[:added].count).to eq(3)
          expect(diff[:removed]).to be_empty
          expect(diff[:unchanged]).to be_empty
        end
      end

      context "when nothing has changed between the head and the base pipeline" do
        subject(:diff) { license_compliance.diff_with(base_compliance) }

        let(:pipeline) { head_pipeline }

        let!(:head_compliance) { project.license_compliance(head_pipeline) }
        let!(:head_pipeline) { create(:ci_pipeline, :success, project: project, builds: [create(:ee_ci_build, :license_scan_v2_1, :success)]) }

        let!(:base_compliance) { project.license_compliance(base_pipeline) }
        let!(:base_pipeline) { create(:ci_pipeline, :success, project: project, builds: [create(:ee_ci_build, :license_scan_v2_1, :success)]) }

        it "returns the differences in licenses introduced by the merge request" do
          expect(diff[:added]).to be_empty
          expect(diff[:removed]).to be_empty
          expect(diff[:unchanged]).to all(be_instance_of(::SCA::LicensePolicy))
          expect(diff[:unchanged].count).to eq(3)
        end
      end

      context "when the base pipeline removed some licenses" do
        subject(:diff) { license_compliance.diff_with(base_compliance) }

        let(:pipeline) { head_pipeline }

        let!(:head_compliance) { project.license_compliance(head_pipeline) }
        let!(:head_pipeline) { create(:ci_pipeline, :success, project: project, builds: [create(:ee_ci_build, :license_scan_v2_1, :success)]) }

        let!(:base_compliance) { project.license_compliance(base_pipeline) }
        let!(:base_pipeline) { create(:ci_pipeline, :success, project: project, builds: [create(:ee_ci_build, :success)]) }

        it "returns the differences in licenses introduced by the merge request" do
          expect(diff[:added]).to be_empty
          expect(diff[:unchanged]).to be_empty
          expect(diff[:removed]).to all(be_instance_of(::SCA::LicensePolicy))
          expect(diff[:removed].count).to eq(3)
        end
      end

      context "when the base pipeline added some licenses" do
        subject(:diff) { license_compliance.diff_with(base_compliance) }

        let(:pipeline) { head_pipeline }

        let!(:head_compliance) { project.license_compliance(head_pipeline) }
        let!(:head_pipeline) { create(:ci_pipeline, :success, project: project, builds: [create(:ee_ci_build, :success)]) }

        let!(:base_compliance) { project.license_compliance(base_pipeline) }
        let!(:base_pipeline) { create(:ci_pipeline, :success, project: project, builds: [create(:ee_ci_build, :license_scan_v2_1, :success)]) }

        it "returns the differences in licenses introduced by the merge request" do
          expect(diff[:added]).to all(be_instance_of(::SCA::LicensePolicy))
          expect(diff[:added].count).to eq(3)
          expect(diff[:removed]).to be_empty
          expect(diff[:unchanged]).to be_empty
        end

        context "when a software license record does not have an spdx identifier" do
          let(:license_name) { 'MIT License' }
          let!(:policy) { create(:software_license_policy, :allowed, project: project, software_license: create(:software_license, name: license_name)) }

          it "falls back to matching detections based on name rather than spdx id" do
            mit = diff[:added].find { |item| item.name == license_name }

            expect(mit).to be_present
            expect(mit.classification).to eql('allowed')
          end
        end
      end
    end

    context "when the license_scanning_sbom_scanner feature flag is enabled" do
      before do
        create(:pm_package_version_license, :with_all_relations, name: "activesupport", purl_type: "gem", version: "5.1.4", license_name: "MIT")
        create(:pm_package_version_license, :with_all_relations, name: "github.com/sirupsen/logrus", purl_type: "golang", version: "v1.4.2", license_name: "MIT")
        create(:pm_package_version_license, :with_all_relations, name: "github.com/sirupsen/logrus", purl_type: "golang", version: "v1.4.2", license_name: "BSD-3-Clause")
        create(:pm_package_version_license, :with_all_relations, name: "org.apache.logging.log4j/log4j-api", purl_type: "maven", version: "2.6.1", license_name: "BSD-3-Clause")
      end

      context "when the head pipeline has not run" do
        subject(:diff) { license_compliance.diff_with(base_compliance) }

        let(:pipeline) { nil }

        let!(:base_compliance) { project.license_compliance(base_pipeline) }
        let!(:base_pipeline) { create(:ee_ci_pipeline, :with_cyclonedx_report, project: project) }

        it "returns the differences in licenses introduced by the merge request" do
          expect(diff[:added]).to all(be_instance_of(::SCA::LicensePolicy))
          expect(diff[:added].count).to eq(3)
          expect(diff[:removed]).to be_empty
          expect(diff[:unchanged]).to be_empty
        end
      end

      context "when nothing has changed between the head and the base pipeline" do
        subject(:diff) { license_compliance.diff_with(base_compliance) }

        let(:pipeline) { head_pipeline }

        let!(:head_compliance) { project.license_compliance(head_pipeline) }
        let!(:head_pipeline) { create(:ee_ci_pipeline, :with_cyclonedx_report, project: project) }

        let!(:base_compliance) { project.license_compliance(base_pipeline) }
        let!(:base_pipeline) { create(:ee_ci_pipeline, :with_cyclonedx_report, project: project) }

        it "returns the differences in licenses introduced by the merge request" do
          expect(diff[:added]).to be_empty
          expect(diff[:removed]).to be_empty
          expect(diff[:unchanged]).to all(be_instance_of(::SCA::LicensePolicy))
          expect(diff[:unchanged].count).to eq(3)
        end
      end

      context "when the base pipeline removed some licenses" do
        subject(:diff) { license_compliance.diff_with(base_compliance) }

        let(:pipeline) { head_pipeline }

        let!(:head_compliance) { project.license_compliance(head_pipeline) }
        let!(:head_pipeline) { create(:ee_ci_pipeline, :with_cyclonedx_report, project: project) }

        let!(:base_compliance) { project.license_compliance(base_pipeline) }
        let!(:base_pipeline) { create(:ee_ci_pipeline, :success, project: project, builds: [create(:ee_ci_build, :success)]) }

        it "returns the differences in licenses introduced by the merge request" do
          expect(diff[:added]).to be_empty
          expect(diff[:unchanged]).to be_empty
          expect(diff[:removed]).to all(be_instance_of(::SCA::LicensePolicy))
          expect(diff[:removed].count).to eq(3)
        end
      end

      context "when the base pipeline added some licenses" do
        subject(:diff) { license_compliance.diff_with(base_compliance) }

        let(:pipeline) { head_pipeline }

        let!(:head_compliance) { project.license_compliance(head_pipeline) }
        let!(:head_pipeline) { create(:ee_ci_pipeline, :success, project: project, builds: [create(:ee_ci_build, :success)]) }

        let!(:base_compliance) { project.license_compliance(base_pipeline) }
        let!(:base_pipeline) { create(:ee_ci_pipeline, :success, project: project, builds: [create(:ee_ci_build, :cyclonedx, :success)]) }

        it "returns the differences in licenses introduced by the merge request" do
          expect(diff[:added]).to all(be_instance_of(::SCA::LicensePolicy))
          expect(diff[:added].count).to eq(3)
          expect(diff[:removed]).to be_empty
          expect(diff[:unchanged]).to be_empty
        end

        context "when a software license record does not have an spdx identifier" do
          let(:license_name) { 'MIT' }
          let!(:policy) { create(:software_license_policy, :allowed, project: project, software_license: create(:software_license, name: license_name)) }

          it "falls back to matching detections based on name rather than spdx id" do
            mit = diff[:added].find { |item| item.name == license_name }

            expect(mit).to be_present
            expect(mit.classification).to eql('allowed')
          end
        end
      end
    end
  end
end
