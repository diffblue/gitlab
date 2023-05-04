# frozen_string_literal: true

require 'spec_helper'

# Store feature-specific specs in `ee/spec/models/merge_request instead of
# making this file longer.
#
# For instance, `ee/spec/models/merge_request/blocking_spec.rb` tests the
# "blocking MRs" feature.
RSpec.describe MergeRequest, feature_category: :code_review_workflow do
  using RSpec::Parameterized::TableSyntax
  include ReactiveCachingHelpers

  let_it_be_with_reload(:project) { create(:project, :repository) }

  let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

  describe 'associations' do
    subject { build_stubbed(:merge_request) }

    it { is_expected.to belong_to(:iteration) }
    it { is_expected.to have_many(:approvals).dependent(:delete_all) }
    it { is_expected.to have_many(:approvers).dependent(:delete_all) }
    it { is_expected.to have_many(:approver_users).through(:approvers) }
    it { is_expected.to have_many(:approver_groups).dependent(:delete_all) }
    it { is_expected.to have_many(:approved_by_users) }
    it { is_expected.to have_one(:merge_train_car) }
    it { is_expected.to have_many(:approval_rules) }
    it { is_expected.to have_many(:approval_merge_request_rule_sources).through(:approval_rules) }
    it { is_expected.to have_many(:approval_project_rules).through(:approval_merge_request_rule_sources) }
    it { is_expected.to have_many(:status_check_responses).class_name('MergeRequests::StatusCheckResponse').inverse_of(:merge_request) }
    it { is_expected.to have_many(:compliance_violations).class_name('MergeRequests::ComplianceViolation') }

    describe 'approval_rules association' do
      describe '#applicable_to_branch' do
        let!(:rule) { create(:approval_merge_request_rule, merge_request: merge_request) }
        let(:branch) { 'stable' }

        subject { merge_request.approval_rules.applicable_to_branch(branch) }

        shared_examples_for 'with applicable rules to specified branch' do
          it { is_expected.to eq([rule]) }
        end

        context 'when there are no associated source rules' do
          it_behaves_like 'with applicable rules to specified branch'
        end

        context 'when there are associated source rules' do
          let(:source_rule) { create(:approval_project_rule, project: merge_request.target_project) }

          before do
            rule.update!(approval_project_rule: source_rule)
          end

          context 'and rule is not modified_from_project_rule' do
            before do
              rule.update!(
                name: source_rule.name,
                approvals_required: source_rule.approvals_required,
                users: source_rule.users,
                groups: source_rule.groups
              )
            end

            context 'and there are no associated protected branches to source rule' do
              it_behaves_like 'with applicable rules to specified branch'
            end

            context 'and there are associated protected branches to source rule' do
              before do
                source_rule.update!(protected_branches: protected_branches)
              end

              context 'and branch matches' do
                let(:protected_branches) { [create(:protected_branch, name: branch)] }

                it_behaves_like 'with applicable rules to specified branch'
              end

              context 'and branch does not match anything' do
                let(:protected_branches) { [create(:protected_branch, name: branch.reverse)] }

                it { is_expected.to be_empty }
              end
            end
          end

          context 'and rule is modified_from_project_rule' do
            before do
              rule.update!(name: 'Overridden Rule')
            end

            it_behaves_like 'with applicable rules to specified branch'
          end

          context 'and rule is overridden but not modified_from_project_rule' do
            before do
              source_rule.update!(name: 'Overridden Rule')
            end

            it_behaves_like 'with applicable rules to specified branch'

            context 'and protected branches exist but branch does not match anything' do
              before do
                source_rule.update!(protected_branches: protected_branches)
              end

              let(:protected_branches) { [create(:protected_branch, name: branch.reverse)] }

              it 'does not find applicable rules', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/394838' do
                expect(subject).to be_empty
              end
            end
          end
        end
      end
    end

    describe '#merge_requests_author_approval?' do
      context 'when project lacks a target_project relation' do
        before do
          merge_request.target_project = nil
        end

        it 'returns false' do
          expect(merge_request.merge_requests_author_approval?).to be false
        end
      end

      context 'when project has a target_project relation' do
        it 'accesses the value from the target_project' do
          expect(merge_request.target_project)
            .to receive(:merge_requests_author_approval?)

          merge_request.merge_requests_author_approval?
        end
      end
    end

    describe '#merge_requests_disable_committers_approval?' do
      context 'when project lacks a target_project relation' do
        before do
          merge_request.target_project = nil
        end

        it 'returns false' do
          expect(merge_request.merge_requests_disable_committers_approval?).to be false
        end
      end

      context 'when project has a target_project relation' do
        it 'accesses the value from the target_project' do
          expect(merge_request.target_project)
            .to receive(:merge_requests_disable_committers_approval?)

          merge_request.merge_requests_disable_committers_approval?
        end
      end
    end
  end

  it_behaves_like 'an editable mentionable with EE-specific mentions' do
    subject { create(:merge_request, :simple) }

    let(:backref_text) { "merge request #{subject.to_reference}" }
    let(:set_mentionable_text) { ->(txt) { subject.description = txt } }
  end

  describe '#allows_multiple_assignees?' do
    it 'does not allow multiple assignees without license' do
      stub_licensed_features(multiple_merge_request_assignees: false)

      merge_request = build_stubbed(:merge_request)

      expect(merge_request.allows_multiple_assignees?).to be(false)
    end

    it 'allows multiple assignees when licensed' do
      stub_licensed_features(multiple_merge_request_assignees: true)

      merge_request = build(:merge_request)

      expect(merge_request.allows_multiple_assignees?).to be(true)
    end
  end

  describe '#allows_multiple_reviewers?' do
    it 'returns false without license' do
      stub_licensed_features(multiple_merge_request_reviewers: false)

      merge_request = build_stubbed(:merge_request)

      expect(merge_request.allows_multiple_reviewers?).to be(false)
    end

    it 'returns true when licensed' do
      stub_licensed_features(multiple_merge_request_reviewers: true)

      merge_request = build(:merge_request)

      expect(merge_request.allows_multiple_reviewers?).to be(true)
    end
  end

  describe '#participants' do
    subject(:participants) { merge_request.participants }

    context 'with approval rule' do
      before do
        approver = create(:approver, target: project)
        second_approver = create(:approver, target: project)

        create(:approval_merge_request_rule, merge_request: merge_request, users: [approver.user, second_approver.user])
      end

      it 'returns only the author as a participant' do
        expect(participants).to contain_exactly(merge_request.author)
      end
    end
  end

  describe '#has_denied_policies?', feature_category: :software_composition_analysis do
    let(:merge_request) { create(:ee_merge_request, :with_license_scanning_reports, source_project: project) }
    let(:apache) { build(:software_license, :apache_2_0) }

    let!(:head_pipeline) do
      create(:ee_ci_pipeline,
             :with_license_scanning_feature_branch,
             project: project,
             ref: merge_request.source_branch,
             sha: merge_request.diff_head_sha)
    end

    let!(:base_pipeline) do
      create(:ee_ci_pipeline,
             project: project,
             ref: merge_request.target_branch,
             sha: merge_request.diff_base_sha)
    end

    before do
      allow_any_instance_of(Ci::CompareSecurityReportsService)
        .to receive(:execute).with(base_pipeline, head_pipeline).and_call_original
    end

    subject { merge_request.has_denied_policies? }

    context 'without existing pipeline' do
      it { is_expected.to be_falsey }
    end

    context 'with existing pipeline' do
      before do
        stub_licensed_features(license_scanning: true)
      end

      context 'without license_scanning report' do
        let(:merge_request) { create(:ee_merge_request, :with_dependency_scanning_reports, source_project: project) }

        it { is_expected.to be_falsey }
      end

      context 'with license_scanning report' do
        context 'without denied policy' do
          it { is_expected.to be_falsey }
        end

        context 'with allowed policy' do
          let(:allowed_policy) { build(:software_license_policy, :allowed, software_license: apache) }

          before do
            project.software_license_policies << allowed_policy
            synchronous_reactive_cache(merge_request)
          end

          it { is_expected.to be_falsey }
        end

        context 'with denied policy' do
          let(:denied_policy) { build(:software_license_policy, :denied, software_license: apache) }

          before do
            project.software_license_policies << denied_policy
            synchronous_reactive_cache(merge_request)
          end

          context 'when the license_scanning_sbom_scanner feature flag is disabled' do
            before do
              stub_feature_flags(license_scanning_sbom_scanner: false)
            end

            it { is_expected.to be_truthy }
          end

          context 'when the license_scanning_sbom_scanner feature flag is enabled' do
            let(:merge_request) { create(:ee_merge_request, :with_cyclonedx_reports, source_project: project) }
            let(:denied_policy) { build(:software_license_policy, :denied, software_license: build(:software_license, :apache_2_0)) }

            before do
              create(:pm_package_version_license, :with_all_relations, name: "nokogiri", purl_type: "gem",
                version: "1.8.0", license_name: "Apache-2.0")
            end

            it { is_expected.to be_truthy }
          end

          context 'with disabled licensed feature' do
            before do
              stub_licensed_features(license_scanning: false)
            end

            it { is_expected.to be_falsey }
          end

          context 'with License-Check enabled' do
            let!(:license_check) { create(:report_approver_rule, :license_scanning, merge_request: merge_request) }

            context 'when rule is not approved' do
              before do
                allow_any_instance_of(ApprovalWrappedRule).to receive(:approved?).and_return(false)
              end

              context 'when the license_scanning_sbom_scanner feature flag is disabled' do
                before do
                  stub_feature_flags(license_scanning_sbom_scanner: false)
                end

                it { is_expected.to be_truthy }
              end

              context 'when the license_scanning_sbom_scanner feature flag is enabled' do
                let(:merge_request) { create(:ee_merge_request, :with_cyclonedx_reports, source_project: project) }
                let(:denied_policy) { build(:software_license_policy, :denied, software_license: build(:software_license, :apache_2_0)) }

                before do
                  create(:pm_package_version_license, :with_all_relations, name: "nokogiri", purl_type: "gem",
                    version: "1.8.0", license_name: "Apache-2.0")
                end

                it { is_expected.to be_truthy }
              end
            end

            context 'when rule is approved' do
              before do
                allow_any_instance_of(ApprovalWrappedRule).to receive(:approved?).and_return(true)
              end

              context 'when the license_scanning_sbom_scanner feature flag is disabled' do
                before do
                  stub_feature_flags(license_scanning_sbom_scanner: false)
                end

                it { is_expected.to be_falsey }
              end

              context 'when the license_scanning_sbom_scanner feature flag is enabled' do
                it { is_expected.to be_falsey }
              end
            end
          end
        end
      end
    end
  end

  describe '#enabled_reports' do
    where(:report_type, :with_reports, :enable_license_scanning_sbom_scanner?, :feature) do
      :sast                | [:with_sast_reports]                                       | false | :sast
      :container_scanning  | [:with_container_scanning_reports]                         | false | :container_scanning
      :dast                | [:with_dast_reports]                                       | false | :dast
      :dependency_scanning | [:with_dependency_scanning_reports]                        | false | :dependency_scanning
      :license_scanning    | [:with_license_scanning_reports]                           | false | :license_scanning
      :license_scanning    | [:with_license_scanning_reports]                           | true  | :license_scanning
      :license_scanning    | [:with_license_scanning_reports, :with_cyclonedx_reports]  | true  | :license_scanning
      :license_scanning    | [:with_cyclonedx_reports]                                  | true  | :license_scanning
      :coverage_fuzzing    | [:with_coverage_fuzzing_reports]                           | false | :coverage_fuzzing
      :secret_detection    | [:with_secret_detection_reports]                           | false | :secret_detection
      :api_fuzzing         | [:with_api_fuzzing_reports]                                | false | :api_fuzzing
    end

    with_them do
      subject { merge_request.enabled_reports[report_type] }

      before do
        stub_licensed_features({ feature => true })
        stub_feature_flags(license_scanning_sbom_scanner: enable_license_scanning_sbom_scanner?)
      end

      context "when head pipeline has reports" do
        let(:merge_request) { create(:ee_merge_request, *with_reports, source_project: project) }

        it { is_expected.to be_truthy }
      end

      context "when head pipeline does not have reports" do
        let(:merge_request) { create(:ee_merge_request, source_project: project) }

        it { is_expected.to be_falsy }
      end
    end
  end

  describe '#approvals_before_merge' do
    where(:license_value, :db_value, :expected) do
      true  | 5   | 5
      true  | nil | nil
      false | 5   | nil
      false | nil | nil
    end

    with_them do
      let(:merge_request) { build(:merge_request, approvals_before_merge: db_value) }

      subject { merge_request.approvals_before_merge }

      before do
        stub_licensed_features(merge_request_approvers: license_value)
      end

      it { is_expected.to eq(expected) }
    end
  end

  describe '#has_security_reports?' do
    subject { merge_request.has_security_reports? }

    before do
      stub_licensed_features(dast: true)
    end

    context 'when head pipeline has security reports' do
      let(:merge_request) { create(:ee_merge_request, :with_dast_reports, source_project: project) }

      it { is_expected.to be_truthy }
    end

    context 'when head pipeline does not have security reports' do
      let(:merge_request) { create(:ee_merge_request, source_project: project) }

      it { is_expected.to be_falsey }
    end
  end

  describe '#has_dependency_scanning_reports?' do
    subject { merge_request.has_dependency_scanning_reports? }

    before do
      stub_licensed_features(container_scanning: true)
    end

    context 'when head pipeline has dependency scannning reports' do
      let(:merge_request) { create(:ee_merge_request, :with_dependency_scanning_reports, source_project: project) }

      it { is_expected.to be_truthy }
    end

    context 'when head pipeline does not have dependency scanning reports' do
      let(:merge_request) { create(:ee_merge_request, source_project: project) }

      it { is_expected.to be_falsey }
    end
  end

  describe '#has_container_scanning_reports?' do
    subject { merge_request.has_container_scanning_reports? }

    before do
      stub_licensed_features(container_scanning: true)
    end

    context 'when head pipeline has container scanning reports' do
      let(:merge_request) { create(:ee_merge_request, :with_container_scanning_reports, source_project: project) }

      it { is_expected.to be_truthy }
    end

    context 'when head pipeline does not have container scanning reports' do
      let(:merge_request) { create(:ee_merge_request, source_project: project) }

      it { is_expected.to be_falsey }
    end
  end

  describe '#has_dast_reports?' do
    subject { merge_request.has_dast_reports? }

    before do
      stub_licensed_features(dast: true)
    end

    context 'when head pipeline has dast reports' do
      let(:merge_request) { create(:ee_merge_request, :with_dast_reports, source_project: project) }

      it { is_expected.to be_truthy }
    end

    context 'when pipeline ran for an older commit than the branch head' do
      let(:pipeline) { create(:ci_empty_pipeline, sha: 'notlatestsha') }
      let(:merge_request) { create(:ee_merge_request, source_project: project, head_pipeline: pipeline) }

      it { is_expected.to be_falsey }
    end

    context 'when head pipeline does not have dast reports' do
      let(:merge_request) { create(:ee_merge_request, source_project: project) }

      it { is_expected.to be_falsey }
    end
  end

  describe '#has_metrics_reports?' do
    subject { merge_request.has_metrics_reports? }

    before do
      stub_licensed_features(metrics_reports: true)
    end

    context 'when head pipeline has metrics reports' do
      let(:merge_request) { create(:ee_merge_request, :with_metrics_reports, source_project: project) }

      it { is_expected.to be_truthy }
    end

    context 'when head pipeline does not have license scanning reports' do
      let(:merge_request) { create(:ee_merge_request, source_project: project) }

      it { is_expected.to be_falsey }
    end
  end

  describe '#has_coverage_fuzzing_reports?' do
    subject { merge_request.has_coverage_fuzzing_reports? }

    before do
      stub_licensed_features(coverage_fuzzing: true)
    end

    context 'when head pipeline has coverage fuzzing reports' do
      let(:merge_request) { create(:ee_merge_request, :with_coverage_fuzzing_reports, source_project: project) }

      it { is_expected.to be_truthy }
    end

    context 'when head pipeline does not have coverage fuzzing reports' do
      let(:merge_request) { create(:ee_merge_request, source_project: project) }

      it { is_expected.to be_falsey }
    end
  end

  describe '#has_api_fuzzing_reports?' do
    subject { merge_request.has_api_fuzzing_reports? }

    before do
      stub_licensed_features(api_fuzzing: true)
    end

    context 'when head pipeline has coverage fuzzing reports' do
      let(:merge_request) { create(:ee_merge_request, :with_api_fuzzing_reports, source_project: project) }

      it { is_expected.to be_truthy }
    end

    context 'when head pipeline does not have coverage fuzzing reports' do
      let(:merge_request) { create(:ee_merge_request, source_project: project) }

      it { is_expected.to be_falsey }
    end
  end

  describe '#calculate_reactive_cache with current_user' do
    let(:current_user) { project.users.take }
    let(:merge_request) { create(:merge_request, source_project: project) }

    subject { merge_request.calculate_reactive_cache(service_class_name, current_user&.id) }

    context 'when given a known service class name' do
      let(:service_class_name) { 'Ci::CompareTestReportsService' }

      it 'does not raises a NameError exception' do
        allow_any_instance_of(service_class_name.constantize).to receive(:execute).and_return(nil)

        expect { subject }.not_to raise_error
      end
    end
  end

  describe '#compare_container_scanning_reports' do
    subject { merge_request.compare_container_scanning_reports(current_user) }

    let(:current_user) { project.users.first }
    let(:merge_request) { create(:merge_request, source_project: project) }

    let!(:base_pipeline) do
      create(:ee_ci_pipeline,
             :with_container_scanning_report,
             project: project,
             ref: merge_request.target_branch,
             sha: merge_request.diff_base_sha)
    end

    before do
      merge_request.update!(head_pipeline_id: head_pipeline.id)
    end

    context 'when head pipeline has container scanning reports' do
      let!(:head_pipeline) do
        create(:ee_ci_pipeline,
               :with_container_scanning_report,
               project: project,
               ref: merge_request.source_branch,
               sha: merge_request.diff_head_sha)
      end

      context 'when reactive cache worker is parsing asynchronously' do
        it 'returns status' do
          expect(subject[:status]).to eq(:parsing)
        end
      end

      context 'when reactive cache worker is inline' do
        before do
          synchronous_reactive_cache(merge_request)
        end

        it 'returns status and data' do
          expect_any_instance_of(Ci::CompareSecurityReportsService)
              .to receive(:execute).with(base_pipeline, head_pipeline).and_call_original

          subject
        end

        context 'when cached results is not latest' do
          before do
            allow_any_instance_of(Ci::CompareSecurityReportsService)
                .to receive(:latest?).and_return(false)
          end

          it 'raises and InvalidateReactiveCache error' do
            expect { subject }.to raise_error(ReactiveCaching::InvalidateReactiveCache)
          end
        end
      end
    end
  end

  describe '#compare_secret_detection_reports' do
    subject { merge_request.compare_secret_detection_reports(current_user) }

    let(:current_user) { project.users.first }
    let(:merge_request) { create(:merge_request, source_project: project) }

    let!(:base_pipeline) do
      create(:ee_ci_pipeline,
             :with_secret_detection_report,
             project: project,
             ref: merge_request.target_branch,
             sha: merge_request.diff_base_sha)
    end

    before do
      merge_request.update!(head_pipeline_id: head_pipeline.id)
    end

    context 'when head pipeline has secret detection reports' do
      let!(:head_pipeline) do
        create(:ee_ci_pipeline,
               :with_secret_detection_report,
               project: project,
               ref: merge_request.source_branch,
               sha: merge_request.diff_head_sha)
      end

      context 'when reactive cache worker is parsing asynchronously' do
        it 'returns status' do
          expect(subject[:status]).to eq(:parsing)
        end
      end

      context 'when reactive cache worker is inline' do
        before do
          synchronous_reactive_cache(merge_request)
        end

        it 'returns status and data' do
          expect_any_instance_of(Ci::CompareSecurityReportsService)
              .to receive(:execute).with(base_pipeline, head_pipeline).and_call_original

          subject
        end

        context 'when cached results is not latest' do
          before do
            allow_any_instance_of(Ci::CompareSecurityReportsService)
                .to receive(:latest?).and_return(false)
          end

          it 'raises and InvalidateReactiveCache error' do
            expect { subject }.to raise_error(ReactiveCaching::InvalidateReactiveCache)
          end
        end
      end
    end
  end

  describe '#compare_sast_reports' do
    subject { merge_request.compare_sast_reports(current_user) }

    let(:current_user) { project.users.first }
    let(:merge_request) { create(:merge_request, source_project: project) }

    let!(:base_pipeline) do
      create(:ee_ci_pipeline,
             :with_sast_report,
             project: project,
             ref: merge_request.target_branch,
             sha: merge_request.diff_base_sha)
    end

    before do
      merge_request.update!(head_pipeline_id: head_pipeline.id)
    end

    context 'when head pipeline has sast reports' do
      let!(:head_pipeline) do
        create(:ee_ci_pipeline,
               :with_sast_report,
               project: project,
               ref: merge_request.source_branch,
               sha: merge_request.diff_head_sha)
      end

      context 'when reactive cache worker is parsing asynchronously' do
        it 'returns status' do
          expect(subject[:status]).to eq(:parsing)
        end
      end

      context 'when reactive cache worker is inline' do
        before do
          synchronous_reactive_cache(merge_request)
        end

        it 'returns status and data' do
          expect_any_instance_of(Ci::CompareSecurityReportsService)
              .to receive(:execute).with(base_pipeline, head_pipeline).and_call_original

          subject
        end

        context 'when cached results is not latest' do
          before do
            allow_any_instance_of(Ci::CompareSecurityReportsService)
                .to receive(:latest?).and_return(false)
          end

          it 'raises and InvalidateReactiveCache error' do
            expect { subject }.to raise_error(ReactiveCaching::InvalidateReactiveCache)
          end
        end
      end
    end
  end

  describe '#compare_license_scanning_reports', feature_category: :software_composition_analysis do
    subject { merge_request.compare_license_scanning_reports(current_user) }

    let(:current_user) { project.users.first }
    let(:merge_request) { create(:merge_request, source_project: project) }

    let!(:base_pipeline) do
      create(:ee_ci_pipeline,
             :with_license_scanning_report,
             project: project,
             ref: merge_request.target_branch,
             sha: merge_request.diff_base_sha)
    end

    before do
      stub_feature_flags(license_scanning_sbom_scanner: false)
      merge_request.update!(head_pipeline_id: head_pipeline.id)
    end

    context 'when head pipeline has license scanning reports' do
      let!(:head_pipeline) do
        create(:ee_ci_pipeline,
               :with_license_scanning_report,
               project: project,
               ref: merge_request.source_branch,
               sha: merge_request.diff_head_sha)
      end

      context 'when reactive cache worker is parsing asynchronously' do
        it 'returns status' do
          expect(subject[:status]).to eq(:parsing)
        end
      end

      context 'when reactive cache worker is inline' do
        before do
          synchronous_reactive_cache(merge_request)
        end

        it 'returns status and data' do
          expect_any_instance_of(Ci::CompareLicenseScanningReportsService)
            .to receive(:execute).with(base_pipeline, head_pipeline).and_call_original

          subject
        end

        context 'cache key includes sofware license policies' do
          let!(:license_1) { create(:software_license_policy, project: project) }
          let!(:license_2) { create(:software_license_policy, project: project) }

          it 'returns key with license information' do
            expect_any_instance_of(Ci::CompareLicenseScanningReportsService)
              .to receive(:execute).with(base_pipeline, head_pipeline).and_call_original

            expect(subject[:key].last).to include("software_license_policies/query-")
          end
        end

        context 'when cached results is not latest' do
          before do
            allow_any_instance_of(Ci::CompareLicenseScanningReportsService)
              .to receive(:latest?).and_return(false)
          end

          it 'raises and InvalidateReactiveCache error' do
            expect { subject }.to raise_error(ReactiveCaching::InvalidateReactiveCache)
          end
        end
      end
    end

    context 'when head pipeline does not have license scanning reports' do
      let!(:head_pipeline) do
        create(:ci_pipeline,
               project: project,
               ref: merge_request.source_branch,
               sha: merge_request.diff_head_sha)
      end

      it 'returns status and error message' do
        expect(subject[:status]).to eq(:error)
        expect(subject[:status_reason]).to eq('This merge request does not have license scanning reports')
      end
    end

    context "when a license scan report is produced from the head pipeline" do
      where(:pipeline_status, :build_types, :expected_status) do
        [
          [:blocked, [:license_scan_v2_1], :parsed],
          [:blocked, [:container_scanning], :error],
          [:blocked, [:license_scan_v2_1, :container_scanning], :parsed],
          [:blocked, [], :error],
          [:failed, [:container_scanning], :error],
          [:failed, [:license_scan_v2_1], :parsed],
          [:failed, [:license_scan_v2_1, :container_scanning], :parsed],
          [:failed, [], :error],
          [:running, [:container_scanning], :error],
          [:running, [:license_scan_v2_1], :parsed],
          [:running, [:license_scan_v2_1, :container_scanning], :parsed],
          [:running, [], :error],
          [:success, [:container_scanning], :error],
          [:success, [:license_scan_v2_1], :parsed],
          [:success, [:license_scan_v2_1, :container_scanning], :parsed],
          [:success, [], :error]
        ]
      end

      with_them do
        let!(:head_pipeline) { create(:ci_pipeline, pipeline_status, project: project, ref: merge_request.source_branch, sha: merge_request.diff_head_sha, builds: builds) }
        let(:builds) { build_types.map { |build_type| create(:ee_ci_build, build_type) } }

        before do
          synchronous_reactive_cache(merge_request)
        end

        specify { expect(subject[:status]).to eq(expected_status) }
      end
    end
  end

  describe '#compare_license_scanning_reports_collapsed', feature_category: :software_composition_analysis do
    subject(:report) { merge_request.compare_license_scanning_reports_collapsed(current_user) }

    let(:current_user) { project.users.first }

    let!(:base_pipeline) do
      create(:ee_ci_pipeline,
             :with_license_scanning_report,
             project: project,
             ref: merge_request.target_branch,
             sha: merge_request.diff_base_sha)
    end

    let!(:head_pipeline) do
      create(:ci_pipeline,
             project: project,
             ref: merge_request.source_branch,
             sha: merge_request.diff_head_sha)
    end

    context 'when service can be executed' do
      before do
        merge_request.update!(head_pipeline_id: head_pipeline.id)

        allow_next_instance_of(::Gitlab::LicenseScanning::ArtifactScanner) do |scanner|
          allow(scanner).to receive(:results_available?).and_return(true)
        end

        allow_next_instance_of(::Gitlab::LicenseScanning::SbomScanner) do |scanner|
          allow(scanner).to receive(:results_available?).and_return(true)
        end
      end

      it 'returns compared report' do
        expect(report[:status]).to eq(:parsing)
      end
    end

    context 'when head pipeline does not have license scanning reports' do
      it 'returns status and error message' do
        expect(subject[:status]).to eq(:error)
      end
    end
  end

  describe '#compare_metrics_reports' do
    subject { merge_request.compare_metrics_reports }

    let(:merge_request) { create(:merge_request, source_project: project) }

    let!(:base_pipeline) do
      create(:ee_ci_pipeline,
             :with_metrics_report,
             project: project,
             ref: merge_request.target_branch,
             sha: merge_request.diff_base_sha)
    end

    before do
      merge_request.update!(head_pipeline_id: head_pipeline.id)
    end

    context 'when head pipeline has metrics reports' do
      let!(:head_pipeline) do
        create(:ee_ci_pipeline,
               :with_metrics_report,
               project: project,
               ref: merge_request.source_branch,
               sha: merge_request.diff_head_sha)
      end

      context 'when reactive cache worker is parsing asynchronously' do
        it 'returns status' do
          expect(subject[:status]).to eq(:parsing)
        end
      end

      context 'when reactive cache worker is inline' do
        before do
          synchronous_reactive_cache(merge_request)
        end

        it 'returns status and data' do
          expect_any_instance_of(Ci::CompareMetricsReportsService)
            .to receive(:execute).with(base_pipeline, head_pipeline).and_call_original

          subject
        end

        context 'when cached results is not latest' do
          before do
            allow_any_instance_of(Ci::CompareMetricsReportsService)
              .to receive(:latest?).and_return(false)
          end

          it 'raises and InvalidateReactiveCache error' do
            expect { subject }.to raise_error(ReactiveCaching::InvalidateReactiveCache)
          end
        end
      end
    end

    context 'when head pipeline does not have metrics reports' do
      let!(:head_pipeline) do
        create(:ci_pipeline,
               project: project,
               ref: merge_request.source_branch,
               sha: merge_request.diff_head_sha)
      end

      it 'returns status and error message' do
        expect(subject[:status]).to eq(:error)
        expect(subject[:status_reason]).to eq('This merge request does not have metrics reports')
      end
    end
  end

  describe '#compare_coverage_fuzzing_reports' do
    subject { merge_request.compare_coverage_fuzzing_reports(current_user) }

    let(:current_user) { project.users.first }
    let(:merge_request) { create(:merge_request, source_project: project) }

    let!(:base_pipeline) do
      create(:ee_ci_pipeline,
             :with_coverage_fuzzing_report,
             project: project,
             ref: merge_request.target_branch,
             sha: merge_request.diff_base_sha)
    end

    before do
      merge_request.update!(head_pipeline_id: head_pipeline.id)
    end

    context 'when head pipeline has coverage fuzzing reports' do
      let!(:head_pipeline) do
        create(:ee_ci_pipeline,
               :with_coverage_fuzzing_report,
               project: project,
               ref: merge_request.source_branch,
               sha: merge_request.diff_head_sha)
      end

      context 'when reactive cache worker is parsing asynchronously' do
        it 'returns status' do
          expect(subject[:status]).to eq(:parsing)
        end
      end

      context 'when reactive cache worker is inline' do
        before do
          synchronous_reactive_cache(merge_request)
        end

        it 'returns status and data' do
          expect_any_instance_of(Ci::CompareSecurityReportsService)
            .to receive(:execute).with(base_pipeline, head_pipeline).and_call_original

          subject
        end

        context 'when cached results is not latest' do
          before do
            allow_any_instance_of(Ci::CompareSecurityReportsService)
                .to receive(:latest?).and_return(false)
          end

          it 'raises and InvalidateReactiveCache error' do
            expect { subject }.to raise_error(ReactiveCaching::InvalidateReactiveCache)
          end
        end
      end
    end
  end

  describe '#compare_api_fuzzing_reports' do
    subject { merge_request.compare_api_fuzzing_reports(current_user) }

    let(:current_user) { project.users.first }
    let(:merge_request) { create(:merge_request, source_project: project) }

    let!(:base_pipeline) do
      create(:ee_ci_pipeline,
             :with_api_fuzzing_report,
             project: project,
             ref: merge_request.target_branch,
             sha: merge_request.diff_base_sha)
    end

    before do
      merge_request.update!(head_pipeline_id: head_pipeline.id)
    end

    context 'when head pipeline has api fuzzing reports' do
      let!(:head_pipeline) do
        create(:ee_ci_pipeline,
               :with_api_fuzzing_report,
               project: project,
               ref: merge_request.source_branch,
               sha: merge_request.diff_head_sha)
      end

      context 'when reactive cache worker is parsing asynchronously' do
        it 'returns status' do
          expect(subject[:status]).to eq(:parsing)
        end
      end

      context 'when reactive cache worker is inline' do
        before do
          synchronous_reactive_cache(merge_request)
        end

        it 'returns status and data' do
          expect_any_instance_of(Ci::CompareSecurityReportsService)
            .to receive(:execute).with(base_pipeline, head_pipeline).and_call_original

          subject
        end

        context 'when cached results is not latest' do
          before do
            allow_any_instance_of(Ci::CompareSecurityReportsService)
                .to receive(:latest?).and_return(false)
          end

          it 'raises an InvalidateReactiveCache error' do
            expect { subject }.to raise_error(ReactiveCaching::InvalidateReactiveCache)
          end
        end
      end
    end
  end

  describe '#use_merge_base_pipeline_for_comparison?' do
    let(:merge_request) { create(:merge_request, :with_codequality_reports, source_project: project) }

    subject { merge_request.use_merge_base_pipeline_for_comparison?(service_class) }

    context 'when service class is Ci::CompareMetricsReportsService' do
      let(:service_class) { ::Ci::CompareMetricsReportsService }

      it { is_expected.to eq(true) }
    end

    context 'when service class is Ci::CompareCodequalityReportsService' do
      let(:service_class) { ::Ci::CompareCodequalityReportsService }

      it { is_expected.to eq(true) }
    end

    context 'when service class is Ci::CompareSecurityReportsService' do
      let(:service_class) { ::Ci::CompareSecurityReportsService }

      it { is_expected.to eq(true) }
    end

    context 'when service class is different' do
      let(:service_class) { ::Ci::GenerateCoverageReportsService }

      it { is_expected.to eq(false) }
    end
  end

  describe '#approver_group_ids=' do
    it 'create approver_groups' do
      group = create :group
      group1 = create :group

      merge_request = create :merge_request

      merge_request.approver_group_ids = "#{group.id}, #{group1.id}"
      merge_request.save!

      expect(merge_request.approver_groups.map(&:group)).to match_array([group, group1])
    end
  end

  describe '#predefined_variables' do
    context 'when merge request has approver feature' do
      before do
        stub_licensed_features(merge_request_approvers: true)
      end

      context 'without any rules' do
        it 'includes variable CI_MERGE_REQUEST_APPROVED=true' do
          expect(merge_request.predefined_variables.to_hash).to include('CI_MERGE_REQUEST_APPROVED' => 'true')
        end
      end

      context 'with a rule' do
        let(:approver) { create(:user) }
        let!(:rule) { create(:approval_merge_request_rule, merge_request: merge_request, approvals_required: 1, users: [approver]) }

        context 'that has been approved' do
          it 'includes variable CI_MERGE_REQUEST_APPROVED=true' do
            create(:approval, merge_request: merge_request, user: approver)

            expect(merge_request.predefined_variables.to_hash).to include('CI_MERGE_REQUEST_APPROVED' => 'true')
          end
        end

        context 'that has not been approved' do
          it 'does not include variable CI_MERGE_REQUEST_APPROVED' do
            expect(merge_request.predefined_variables.to_hash.keys).not_to include('CI_MERGE_REQUEST_APPROVED')
          end
        end
      end
    end

    context 'when merge request does not have approver feature' do
      before do
        stub_licensed_features(merge_request_approvers: false)
      end

      it 'does not include variable CI_MERGE_REQUEST_APPROVED' do
        expect(merge_request.predefined_variables.to_hash.keys).not_to include('CI_MERGE_REQUEST_APPROVED')
      end
    end
  end

  describe '#mergeable_state?' do
    subject { merge_request.mergeable_state? }

    let(:project_with_approver) { create(:project, :repository) }
    let(:merge_request) { create(:merge_request, source_project: project_with_approver, target_project: project_with_approver) }

    let_it_be(:user) { create(:user) }

    context 'when using approvals' do
      before do
        merge_request.target_project.update!(approvals_before_merge: 1)
        project.add_developer(user)
      end

      context 'when not approved' do
        it 'is not mergeable' do
          is_expected.to be_falsey
        end
      end

      context 'when approved' do
        before do
          merge_request.approvals.create!(user: user)
        end

        it 'is mergeable' do
          is_expected.to be_truthy
        end
      end
    end

    context 'when blocking merge requests' do
      before do
        stub_licensed_features(blocking_merge_requests: true)
      end

      context 'when the merge request is blocked' do
        let(:merge_request) { create(:merge_request, :blocked, source_project: project, target_project: project) }

        it 'is not mergeable' do
          is_expected.to be_falsey
        end
      end

      context 'when merge request is not blocked' do
        it 'is mergeable' do
          is_expected.to be_truthy
        end
      end
    end

    context 'when running license_scanning ci job' do
      context 'when merge request has denied policies' do
        before do
          allow(merge_request).to receive(:has_denied_policies?).and_return(true)
        end

        it 'is not mergeable' do
          is_expected.to be_falsey
        end
      end

      context 'when merge request has no denied policies' do
        before do
          allow(merge_request).to receive(:has_denied_policies?).and_return(false)
        end

        it 'is mergeable' do
          is_expected.to be_truthy
        end
      end
    end
  end

  describe '#on_train?' do
    subject { merge_request.on_train? }

    context 'when the merge request is on a merge train' do
      let(:merge_request) do
        create(:merge_request, :on_train, source_project: project, target_project: project)
      end

      it { is_expected.to be_truthy }
    end

    context 'when the merge request was on a merge train' do
      let(:merge_request) do
        create(:merge_request, :on_train,
          status: MergeTrains::Car.state_machines[:status].states[:merged].value,
          source_project: project, target_project: project)
      end

      it { is_expected.to be_falsy }
    end

    context 'when the merge request is not on a merge train' do
      let(:merge_request) do
        create(:merge_request, source_project: project, target_project: project)
      end

      it { is_expected.to be_falsy }
    end
  end

  describe 'review time sorting' do
    def create_mr(metrics_data = {})
      create(:merge_request, :with_productivity_metrics, metrics_data: metrics_data)
    end

    it 'orders by first_comment_at or first_approved_at whatever is earlier' do
      mr1 = create_mr(first_comment_at: 1.day.ago)
      mr2 = create_mr(first_comment_at: 3.days.ago)
      mr3 = create_mr(first_approved_at: 5.days.ago)
      mr4 = create_mr(first_comment_at: 1.day.ago, first_approved_at: 4.days.ago)
      mr5 = create_mr(first_comment_at: nil, first_approved_at: nil)

      expect(described_class.order_review_time_desc).to match([mr3, mr4, mr2, mr1, mr5])
      expect(described_class.sort_by_attribute('review_time_desc')).to match([mr3, mr4, mr2, mr1, mr5])
    end
  end

  describe '#security_reports_up_to_date?' do
    let(:merge_request) do
      create(:ee_merge_request,
             source_project: project,
             source_branch: 'feature1',
             target_branch: project.default_branch)
    end

    before do
      create(:ee_ci_pipeline,
             :with_sast_report,
             project: project,
             ref: merge_request.target_branch)
    end

    subject { merge_request.security_reports_up_to_date? }

    context 'when the target branch security reports are up to date' do
      it { is_expected.to be true }
    end

    context 'when the target branch security reports are out of date' do
      before do
        create(:ee_ci_pipeline, :failed, project: project, ref: merge_request.target_branch)
      end

      it { is_expected.to be false }
    end
  end

  describe '#audit_details' do
    it 'equals to the title' do
      merge_request = create(:merge_request, title: 'I am a title')

      expect(merge_request.audit_details).to eq(merge_request.title)
    end
  end

  describe '#latest_pipeline_for_target_branch' do
    context 'without pipeline' do
      it 'return nil' do
        expect(merge_request.latest_pipeline_for_target_branch).to be_nil
      end
    end

    context 'with existing pipeline' do
      let!(:target_branch_pipeline) do
        create(:ee_ci_pipeline,
                project: project,
                ref: merge_request.target_branch)
      end

      it 'returns the pipeline related to the target branch' do
        expect(merge_request.latest_pipeline_for_target_branch).to eq(target_branch_pipeline)
      end
    end
  end

  describe '#validate_reviewer_length' do
    let(:reviewer1) { create(:user) }
    let(:reviewer2) { create(:user) }
    let(:reviewer3) { create(:user) }

    subject { create(:merge_request) }

    before do
      stub_const("Issuable::MAX_NUMBER_OF_ASSIGNEES_OR_REVIEWERS", 2)
    end

    it 'will not exceed the reviewer limit' do
      expect do
        subject.update!(reviewers: [reviewer1, reviewer2, reviewer3])
      end.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe '#sync_project_approval_rules_for_policy_configuration' do
    let_it_be(:merge_request) { create(:ee_merge_request, source_project: project) }
    let_it_be(:policy_configuration) { create(:security_orchestration_policy_configuration, project: project) }
    let_it_be(:project_approval_rule_without_configuration) { create(:approval_project_rule, project: project) }

    let_it_be(:project_approval_rule) do
      create(:approval_project_rule, :scan_finding,
        project: project,
        security_orchestration_policy_configuration: policy_configuration,
        scanners: %w[sast],
        approvals_required: 2
      )
    end

    subject do
      merge_request.sync_project_approval_rules_for_policy_configuration(policy_configuration.id)
    end

    it 'creates approval rules for project' do
      subject

      expect(merge_request.approval_rules.first.approval_project_rule).to eq(project_approval_rule)
    end

    it 'does not create approval rules for other configuration' do
      subject

      expect(merge_request.approval_rules.map(&:approval_project_rule)).not_to include(project_approval_rule_without_configuration)
    end

    context 'when mr approval rules already exist' do
      let_it_be(:mr_approval_rule) do
        create(:report_approver_rule, :scan_finding,
          merge_request: merge_request,
          approvals_required: 1
        )
      end

      let_it_be(:approval_rule_source) do
        create(:approval_merge_request_rule_source,
          approval_merge_request_rule: mr_approval_rule,
          approval_project_rule: project_approval_rule
        )
      end

      it 'updates approval rule' do
        subject

        expect(mr_approval_rule.reload.approvals_required).to eq(2)
      end
    end

    context 'when merge request is already merged' do
      let_it_be(:merge_request) { create(:ee_merge_request, source_project: project, state: :merged) }

      it 'does not create or update approval rule' do
        subject

        expect(merge_request.approval_rules).to be_empty
      end
    end
  end

  context 'scopes' do
    let_it_be(:merge_request) { create(:ee_merge_request) }
    let_it_be(:merge_request_with_head_pipeline) { create(:ee_merge_request, :with_metrics_reports) }

    describe '.with_head_pipeline' do
      it 'returns MRs that have a head pipeline' do
        expect(described_class.with_head_pipeline).to eq([merge_request_with_head_pipeline])
      end
    end

    describe '.with_applied_scan_result_policies' do
      let_it_be(:scan_finding_approval_rule) { create(:report_approver_rule, :code_coverage) }
      let_it_be(:code_coverage_approval_rule) { create(:report_approver_rule, :scan_finding) }

      it 'returns MRs that have applied scan result policies' do
        expect(described_class.with_applied_scan_result_policies).to eq([code_coverage_approval_rule.merge_request])
      end
    end

    describe '.for_projects_with_security_policy_project' do
      let_it_be(:security_orchestration_policy_configuration) { create(:security_orchestration_policy_configuration) }

      let_it_be(:merge_request_with_security_policy_project) do
        create(:ee_merge_request, source_project: security_orchestration_policy_configuration.project)
      end

      let_it_be(:merge_request_without_security_policy_project) { create(:ee_merge_request) }

      it 'returns MRs for projects with security policy project on target project' do
        expect(described_class.for_projects_with_security_policy_project).to eq(
          [merge_request_with_security_policy_project])
      end
    end
  end

  context 'after_update hooks' do
    describe 'sync_merge_request_compliance_violation' do
      let_it_be(:merge_request) do
        create(:merge_request, source_project: project, target_project: project, state: :merged, title: 'old MR title')
      end

      let_it_be(:compliance_violation) do
        create(:compliance_violation, :approved_by_committer, severity_level: :low, merge_request: merge_request, title: 'old MR title')
      end

      it "calls sync_merge_request_compliance_violation when the MR title is updated" do
        expect(merge_request.compliance_violations.pluck(:title)).to contain_exactly('old MR title')
        expect(merge_request).to receive(:sync_merge_request_compliance_violation).and_call_original

        merge_request.update_attribute(:title, "new MR title")

        expect(merge_request.compliance_violations.pluck(:title)).to contain_exactly('new MR title')
      end

      it "does not call sync_merge_request_compliance_violation when the MR title is not updated" do
        expect(merge_request).not_to receive(:sync_merge_request_compliance_violation)

        merge_request.update_attribute(:milestone, Milestone.last)
      end
    end
  end
end
