# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(
  Gitlab::BackgroundMigration::MigrateVulnerabilitiesFeedbackToVulnerabilitiesStateTransition,
  feature_category: :vulnerability_management
) do
  let(:feedback_types) do
    {
      dismissal: 0,
      issue: 1,
      merge_request: 2
    }
  end

  let(:vulnerability_states) do
    {
      detected: 1,
      confirmed: 4,
      resolved: 3,
      dismissed: 2
    }
  end

  let(:comment_max_length) { 50 }

  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:users) { table(:users) }
  let(:members) { table(:members) }
  let(:vulnerability_identifiers) { table(:vulnerability_identifiers) }
  let(:vulnerability_scanners) { table(:vulnerability_scanners) }
  let(:vulnerability_findings) { table(:vulnerability_occurrences) }
  let(:vulnerabilities) { table(:vulnerabilities) }
  let(:vulnerability_feedback) { table(:vulnerability_feedback) }
  let(:vulnerability_state_transitions) { table(:vulnerability_state_transitions) }
  let(:security_scans) { table(:security_scans) }
  let(:security_findings) { table(:security_findings) }
  let(:ci_builds) { table(:ci_builds, database: :ci) { |model| model.primary_key = :id } }
  let(:ci_job_artifacts) { table(:ci_job_artifacts, database: :ci) }
  let(:ci_pipelines) { table(:ci_pipelines, database: :ci) }

  let!(:user) { create_user(email: "test1@example.com", username: "test1") }
  let!(:namespace) { namespaces.create!(name: "test-1", path: "test-1", owner_id: user.id) }
  let!(:project) do
    projects.create!(id: 9999, namespace_id: namespace.id, project_namespace_id: namespace.id, creator_id: user.id)
  end

  let!(:membership) do
    members.create!(access_level: 50, source_id: project.id, source_type: "Project", user_id: user.id, state: 0,
                    notification_level: 3, type: "ProjectMember", member_namespace_id: namespace.id)
  end

  let(:migration_attrs) do
    {
      start_id: vulnerability_feedback.minimum(:id),
      end_id: vulnerability_feedback.maximum(:id),
      batch_table: :vulnerability_feedback,
      batch_column: :id,
      sub_batch_size: 100,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    }
  end

  shared_examples 'a migration updating migrated_to_state_transition column' do
    let(:feedback) { vulnerability_feedback.first }

    it 'updates the migrated_to_state_transition column' do
      expect(feedback.migrated_to_state_transition).to be_falsey

      subject

      expect(feedback.reload.migrated_to_state_transition).to be_truthy
    end
  end

  before do
    stub_const("EE::#{described_class}::MAX_COMMENT_LENGTH", comment_max_length)
  end

  describe "#perform", feature_category: :vulnerability_management do
    before do
      stub_licensed_features(security_dashboard: true)
    end

    let!(:scanner) { create_scanner(project) }
    let!(:finding) { create_finding(project, scanner) }

    subject { described_class.new(**migration_attrs).perform }

    context "when a Finding has no Vulnerability" do
      before do
        create_feedback(
          project,
          user,
          finding.report_type,
          feedback_types[:dismissal],
          finding.project_fingerprint,
          finding.uuid,
          comment: "this feedback is for a Vulnerabilities::Finding"
        )
      end

      context "when there was a problem saving the Vulnerability" do # rubocop:disable RSpec/MultipleMemoizedHelpers
        let(:errors_like_object) do
          instance_double("ActiveModel::Errors", any?: true, full_messages: ["Title can't be blank"])
        end

        let(:problematic_vulnerability) { instance_double("Vulnerability", valid?: false, errors: errors_like_object) }

        before do
          # https://docs.gitlab.com/ee/development/database/batched_background_migrations.html#isolation
          # forbids using application code in background migrations but we have an exception for this
          # in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/97699#note_1102465241
          allow_next_instance_of(::Vulnerabilities::CreateService) do |service|
            allow(service).to receive(:execute).and_return(problematic_vulnerability)
          end
        end

        it "doesn't create a Vulnerability record" do
          expect { subject }.to change { vulnerabilities.count }.by(0)
        end

        it "logs an error" do
          expect_next_instance_of(::Gitlab::BackgroundMigration::Logger) do |logger|
            params = {
              class: "MigrateVulnerabilitiesFeedbackToVulnerabilitiesStateTransition",
              errors: "Title can't be blank",
              message: "Failed to create Vulnerability",
              vulnerability_finding_id: finding.id
            }
            expect(logger).to receive(:error).once.with(params)
          end

          subject
        end
      end

      it 'creates a Vulnerability from the Vulnerabilities::Finding' do
        expect { subject }.to change { vulnerabilities.count }.by(1)
      end

      it 'creates a Vulnerabilities::StateTransition from the Vulnerabilities::Feedback' do
        subject

        state_transition = vulnerability_state_transitions.last
        expect(state_transition.from_state).to eq(vulnerability_states[:detected])
        expect(state_transition.to_state).to eq(vulnerability_states[:dismissed])
        expect(state_transition.author_id).to eq(vulnerability_feedback.last.author_id)
        expect(state_transition.vulnerability_id).to eq(vulnerabilities.last.id)
      end
    end

    context "when there's only a Security::Finding" do
      before do
        sast_category = 0
        sast_scan_type = 1

        nonexistent_project_fingerprint = SecureRandom.hex(20)
        # this UUID would be calculcated from gl-sast-report-with-signatures-and-flags.json fixture
        known_uuid = "429005aa-8b32-58a9-b2ea-bc8ae80b0963"
        ci_pipeline = create_ci_pipeline(project_id: project.id)
        ci_build = create_ci_build(
          project_id: project.id,
          status: "success",
          commit_id: ci_pipeline.id
        )
        # rubocop:disable RSpec/FactoriesInMigrationSpecs
        # I'm not sure how to properly handle this since the path is somehow calculated
        # like tmp/tests/artifacts/5f/9c/5f9c4ab08cac7457e9111a30e4664920607ea2c115a1433d7be98e97e64244ca/2022_09_20
        # /21/21/gl-sast-report-with-signatures-and-flags.json
        create(:ee_ci_job_artifact, :sast_with_signatures_and_vulnerability_flags, job_id: ci_build.id)
        # rubocop:enable RSpec/FactoriesInMigrationSpecs
        security_scan = create_security_scan(ci_build, sast_scan_type, project_id: project.id)
        @security_finding = create_security_finding(security_scan, scanner, uuid: known_uuid)
        @feedback = create_feedback(
          project,
          user,
          sast_category,
          feedback_types[:dismissal],
          nonexistent_project_fingerprint,
          known_uuid,
          comment: "this feedback is for a Security::Finding"
        )
      end

      context "when creating any associated record fails" do # rubocop:disable RSpec/MultipleMemoizedHelpers
        let(:error_response) { instance_double(ServiceResponse, message: "an error", error?: true) }

        before do
          # https://docs.gitlab.com/ee/development/database/batched_background_migrations.html#isolation
          # forbids using application code in background migrations but we have an exception for this
          # in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/97699#note_1102465241
          allow_next_instance_of(::Vulnerabilities::FindOrCreateFromSecurityFindingService) do |service|
            allow(service).to receive(:execute).and_return(error_response)
          end
        end

        it "doesn't create a Vulnerability record" do
          expect { subject }.to change { vulnerabilities.count }.by(0)
        end

        # rubocop:disable RSpec/InstanceVariable
        it "logs an error" do
          expect_next_instance_of(::Gitlab::BackgroundMigration::Logger) do |logger|
            params = {
              message: "Failed to create Vulnerability from Security::Finding",
              class: "MigrateVulnerabilitiesFeedbackToVulnerabilitiesStateTransition",
              error: "an error",
              security_finding_uuid: @security_finding.uuid,
              vulnerability_feedback_id: @feedback.id
            }
            expect(logger).to receive(:error).once.with(params)
          end

          subject
        end
        # rubocop:enable RSpec/InstanceVariable
      end

      it 'creates a Vulnerability from the Security::Finding' do
        expect { subject }.to change { vulnerabilities.count }.by(1)
      end

      it 'creates a Vulnerabilities::StateTransition from the Vulnerabilities::Feedback' do
        subject

        state_transition = vulnerability_state_transitions.last
        expect(state_transition.from_state).to eq(vulnerability_states[:detected])
        expect(state_transition.to_state).to eq(vulnerability_states[:dismissed])
        expect(state_transition.author_id).to eq(vulnerability_feedback.last.author_id)
        expect(state_transition.vulnerability_id).to eq(vulnerabilities.last.id)
      end

      it_behaves_like 'a migration updating migrated_to_state_transition column'
    end

    context "when a Vulnerability is dismissed" do
      before do
        vulnerability = create_vulnerability(project, user)
        finding = create_finding(project, scanner, vulnerability_id: vulnerability.id)
        create_feedback(
          project,
          user,
          finding.report_type,
          feedback_types[:dismissal],
          finding.project_fingerprint,
          finding.uuid
        )
      end

      context 'when the StateTransition is invalid' do # rubocop:disable RSpec/MultipleMemoizedHelpers
        let(:klass) { "EE::#{described_class}::StateTransition".constantize }

        let(:errors_like_object) do
          instance_double("ActiveModel::Errors", any?: true, full_messages: ["An error"])
        end

        let(:invalid_state_transition) do
          instance_double(klass.to_s, valid?: false, errors: errors_like_object)
        end

        before do
          allow(klass).to receive(:new).and_return(invalid_state_transition)
        end

        it "doesn't create a StateTransition" do
          expect { subject }.not_to change { vulnerability_state_transitions.count }
        end

        it "logs an error" do
          expect_next_instance_of(::Gitlab::BackgroundMigration::Logger) do |logger|
            params = {
              class: "MigrateVulnerabilitiesFeedbackToVulnerabilitiesStateTransition",
              errors: "An error",
              message: "Failed to create a StateTransition",
              vulnerability_id: kind_of(Integer),
              feedback_id: kind_of(Integer)
            }
            expect(logger).to receive(:error).once.with(params)
          end

          subject
        end
      end

      it "creates a valid Vulnerabilities::StateTransition record for a dismissed Vulnerability" do
        subject

        state_transition = vulnerability_state_transitions.last
        expect(vulnerability_state_transitions.count).to eq(1)
        expect(state_transition.from_state).to eq(vulnerability_states[:detected])
        expect(state_transition.to_state).to eq(vulnerability_states[:dismissed])
        expect(state_transition.author_id).to eq(vulnerability_feedback.last.author_id)
        expect(state_transition.vulnerability_id).to eq(vulnerabilities.last.id)
      end
    end

    # rubocop:disable RSpec/MultipleMemoizedHelpers
    context "when a Vulnerability is dismissed with a comment" do
      let(:comment) { "This is a test comment" }
      let(:vulnerability) { create_vulnerability(project, user) }
      let(:finding) { create_finding(project, scanner, vulnerability_id: vulnerability.id) }
      let(:feedback) do
        create_feedback(
          project,
          user,
          finding.report_type,
          feedback_types[:dismissal],
          finding.project_fingerprint,
          finding.uuid,
          comment: comment,
          comment_author_id: user.id
        )
      end

      before do
        create_feedback(
          project,
          user,
          finding.report_type,
          feedback_types[:dismissal],
          finding.project_fingerprint,
          finding.uuid,
          comment: comment,
          comment_author_id: user.id
        )
      end

      it "retains the comment" do
        subject

        state_transition = vulnerability_state_transitions.last
        expect(vulnerability_state_transitions.count).to eq(1)
        expect(state_transition.from_state).to eq(vulnerability_states[:detected])
        expect(state_transition.to_state).to eq(vulnerability_states[:dismissed])
        expect(state_transition.comment).to eq(comment)
        expect(state_transition.author_id).to eq(vulnerability_feedback.last.author_id)
        expect(state_transition.vulnerability_id).to eq(vulnerabilities.last.id)
      end

      it_behaves_like 'a migration updating migrated_to_state_transition column'

      context "when a Vulnerability is dismissed with too long comment" do
        let(:comment) { "<body>#{'a' * comment_max_length * 2}</body>" }

        it "retains strips HTML tags and truncates the comment" do
          subject

          state_transition = vulnerability_state_transitions.last
          expect(vulnerability_state_transitions.count).to eq(1)
          expect(state_transition.from_state).to eq(vulnerability_states[:detected])
          expect(state_transition.to_state).to eq(vulnerability_states[:dismissed])
          expect(state_transition.comment.length).to eq(comment_max_length)
          expect(state_transition.author_id).to eq(vulnerability_feedback.last.author_id)
          expect(state_transition.vulnerability_id).to eq(vulnerabilities.last.id)
        end

        it_behaves_like 'a migration updating migrated_to_state_transition column'
      end
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers

    context "when a Vulnerability is dismissed with a dismissal reason" do
      dismissal_reason = 3 # used_in_test

      before do
        vulnerability = create_vulnerability(project, user)
        finding = create_finding(project, scanner, vulnerability_id: vulnerability.id)
        create_feedback(
          project,
          user,
          finding.report_type,
          feedback_types[:dismissal],
          finding.project_fingerprint,
          finding.uuid,
          dismissal_reason: dismissal_reason
        )
      end

      it "retains the dismissal_reason" do
        subject

        state_transition = vulnerability_state_transitions.last
        expect(vulnerability_state_transitions.count).to eq(1)
        expect(state_transition.from_state).to eq(vulnerability_states[:detected])
        expect(state_transition.to_state).to eq(vulnerability_states[:dismissed])
        expect(state_transition.dismissal_reason).to eq(dismissal_reason)
        expect(state_transition.vulnerability_id).to eq(vulnerabilities.last.id)
      end

      it_behaves_like 'a migration updating migrated_to_state_transition column'
    end
  end

  private

  def create_security_scan(build, scan_type, overrides = {})
    attrs = {
      build_id: build.id,
      scan_type: scan_type
    }

    security_scans.create!(attrs)
  end

  def create_ci_pipeline(overrides = {})
    attrs = {
      partition_id: 100
    }.merge(overrides)
    ci_pipelines.create!(attrs)
  end

  def create_ci_build(overrides = {})
    attrs = {
      type: 'Ci::Build',
      partition_id: 100
    }.merge(overrides)
    ci_builds.create!(attrs)
  end

  def create_ci_job_artifact(project, file_type, build, overrides = {})
    attrs = {
      project_id: project.id,
      file_type: file_type,
      job_id: build.id
    }.merge(overrides)

    ci_job_artifacts.create!(attrs)
  end

  def create_security_finding(security_scan, scanner, overrides = {})
    attrs = {
      scan_id: security_scan.id,
      scanner_id: scanner.id,
      severity: 2 # unknown
    }.merge(overrides)

    security_findings.create!(attrs)
  end

  def create_scanner(project, overrides = {})
    attrs = {
      project_id: project.id,
      external_id: "test_vulnerability_scanner",
      name: "Test Vulnerabilities::Scanner"
    }.merge(overrides)

    vulnerability_scanners.create!(attrs)
  end

  def create_finding(project, scanner, overrides = {})
    attrs = {
      project_id: project.id,
      scanner_id: scanner.id,
      severity: 5, # medium
      confidence: 2, # unknown,
      report_type: 99, # generic
      primary_identifier_id: create_identifier(project).id,
      project_fingerprint: SecureRandom.hex(20),
      location_fingerprint: SecureRandom.hex(20),
      uuid: SecureRandom.uuid,
      name: "CVE-2018-1234",
      raw_metadata: "{}",
      metadata_version: "test:1.0"
    }.merge(overrides)

    vulnerability_findings.create!(attrs)
  end

  def create_identifier(project, overrides = {})
    attrs = {
      project_id: project.id,
      external_id: "CVE-2018-1234",
      external_type: "CVE",
      name: "CVE-2018-1234",
      fingerprint: SecureRandom.hex(20)
    }.merge(overrides)

    vulnerability_identifiers.create!(attrs)
  end

  def create_vulnerability(project, user, overrides = {})
    attrs = {
      title: "test",
      severity: 6, # high
      confidence: 6, # high
      report_type: 0, # sast
      description: "test",
      project_id: project.id,
      author_id: overrides.fetch(:author_id) { user.id }
    }

    vulnerabilities.create!(attrs)
  end

  def create_feedback(project, user, category, feedback_type, project_fingerprint, finding_uuid, overrides = {})
    attrs = {
      project_fingerprint: project_fingerprint,
      category: category,
      project_id: project.id,
      author_id: user.id,
      feedback_type: feedback_type,
      finding_uuid: finding_uuid
    }.merge(overrides)

    vulnerability_feedback.create!(attrs)
  end

  def create_user(overrides = {})
    attrs = {
      email: "test@example.com",
      notification_email: "test@example.com",
      name: "test",
      username: "test",
      state: "active",
      projects_limit: 10
    }.merge(overrides)

    users.create!(attrs)
  end
end
