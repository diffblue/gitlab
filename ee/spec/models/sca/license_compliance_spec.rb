# frozen_string_literal: true

require "spec_helper"

RSpec.describe SCA::LicenseCompliance do
  let(:license_compliance) { described_class.new(project, pipeline) }

  let_it_be(:project) { create(:project, :repository, :private) }

  let(:mit) { create(:software_license, :mit) }
  let(:other_license) { create(:software_license, name: "SOFTWARE-LICENSE", spdx_identifier: "Other-Id") }

  before do
    stub_licensed_features(license_scanning: true)
  end

  describe "#policies" do
    subject(:policies) { license_compliance.policies }

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

  describe "#find_policies" do
    let!(:pipeline) { create(:ci_pipeline, :success, project: project, builds: [create(:ee_ci_build, :success, :license_scan_v2_1)]) }
    let!(:mit_policy) { create(:software_license_policy, :denied, software_license: mit, project: project) }
    let!(:other_license_policy) { create(:software_license_policy, :allowed, software_license: other_license, project: project) }

    def assert_matches(item, expected = {})
      actual = expected.keys.index_with do |attribute|
        item.public_send(attribute)
      end
      expect(actual).to eql(expected)
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
          url: '',
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

  describe "#latest_build_for_default_branch" do
    subject { license_compliance.latest_build_for_default_branch }

    let(:pipeline) { nil }

    let(:regular_build) { create(:ci_build, :success) }
    let(:license_scan_build) { create(:ee_ci_build, :license_scan_v2_1, :success) }

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

  describe "#diff_with" do
    context "when the head pipeline has not run" do
      subject(:diff) { license_compliance.diff_with(base_compliance) }

      let(:pipeline) { nil }

      let!(:base_compliance) { project.license_compliance(base_pipeline) }
      let!(:base_pipeline) { create(:ci_pipeline, :success, project: project, builds: [license_scan_build]) }
      let(:license_scan_build) { create(:ee_ci_build, :license_scan_v2_1, :success) }

      specify { expect(diff[:added]).to all(be_instance_of(::SCA::LicensePolicy)) }
      specify { expect(diff[:added].count).to eq(3) }
      specify { expect(diff[:removed]).to be_empty }
      specify { expect(diff[:unchanged]).to be_empty }
    end

    context "when nothing has changed between the head and the base pipeline" do
      subject(:diff) { license_compliance.diff_with(base_compliance) }

      let(:pipeline) { head_pipeline }

      let!(:head_compliance) { project.license_compliance(head_pipeline) }
      let!(:head_pipeline) { create(:ci_pipeline, :success, project: project, builds: [create(:ee_ci_build, :license_scan_v2_1, :success)]) }

      let!(:base_compliance) { project.license_compliance(base_pipeline) }
      let!(:base_pipeline) { create(:ci_pipeline, :success, project: project, builds: [create(:ee_ci_build, :license_scan_v2_1, :success)]) }

      specify { expect(diff[:added]).to be_empty }
      specify { expect(diff[:removed]).to be_empty }
      specify { expect(diff[:unchanged]).to all(be_instance_of(::SCA::LicensePolicy)) }
      specify { expect(diff[:unchanged].count).to eq(3) }
    end

    context "when the base pipeline removed some licenses" do
      subject(:diff) { license_compliance.diff_with(base_compliance) }

      let(:pipeline) { head_pipeline }

      let!(:head_compliance) { project.license_compliance(head_pipeline) }
      let!(:head_pipeline) { create(:ci_pipeline, :success, project: project, builds: [create(:ee_ci_build, :license_scan_v2_1, :success)]) }

      let!(:base_compliance) { project.license_compliance(base_pipeline) }
      let!(:base_pipeline) { create(:ci_pipeline, :success, project: project, builds: [create(:ee_ci_build, :success)]) }

      specify { expect(diff[:added]).to be_empty }
      specify { expect(diff[:unchanged]).to be_empty }
      specify { expect(diff[:removed]).to all(be_instance_of(::SCA::LicensePolicy)) }
      specify { expect(diff[:removed].count).to eq(3) }
    end

    context "when the base pipeline added some licenses" do
      subject(:diff) { license_compliance.diff_with(base_compliance) }

      let(:pipeline) { head_pipeline }

      let!(:head_compliance) { project.license_compliance(head_pipeline) }
      let!(:head_pipeline) { create(:ci_pipeline, :success, project: project, builds: [create(:ee_ci_build, :success)]) }

      let!(:base_compliance) { project.license_compliance(base_pipeline) }
      let!(:base_pipeline) { create(:ci_pipeline, :success, project: project, builds: [create(:ee_ci_build, :license_scan_v2_1, :success)]) }

      specify { expect(diff[:added]).to all(be_instance_of(::SCA::LicensePolicy)) }
      specify { expect(diff[:added].count).to eq(3) }
      specify { expect(diff[:removed]).to be_empty }
      specify { expect(diff[:unchanged]).to be_empty }

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
end
