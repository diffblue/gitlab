# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::GenerateScanFindingRulesWorker do
  describe '#perform' do
    let_it_be(:current_user) { create(:user) }
    let_it_be(:project) { create(:project) }

    let(:approval_rule_trait) { :license_scanning }
    let(:security_policies_enabled) { true }
    let(:approval_rule) do
      create(:approval_project_rule, approval_rule_trait, project: project, users: [project.team.owners.first])
    end

    before do
      stub_licensed_features(security_orchestration_policies: security_policies_enabled)
      allow(project).to receive(:licensed_feature_available?)
        .with(:security_orchestration_policies)
        .and_return(security_policies_enabled)
    end

    subject { described_class.new.perform(approval_rule.id) }

    shared_examples 'deletes the rule and logs warning' do |warning|
      let(:full_warning) do
        "Failed to create scan result policy for approval_rule_id: "\
        "#{approval_rule.id} #{warning}"
      end

      it 'deletes the rule and logs warning' do
        expect(Gitlab::AppLogger).to receive(:warn).with(full_warning)

        expect {subject}.to change(ApprovalProjectRule, :count).from(1).to(0)
      end
    end

    context 'with vulnerability rule' do
      let(:approval_rule_trait) { :vulnerability }

      include_examples 'deletes the rule and logs warning', "with UserNamespace is not supported"

      context 'within a group' do
        let_it_be(:group) { create(:group) }
        let_it_be(:project) { create(:project, group: group) }

        let(:expected_policy) do
          {
            actions: [
              {
                approvals_required: approval_rule.approvals_required,
                type: "require_approval",
                user_approvers_ids: [current_user.id]
              }
            ],
            rules: [
              {
                branches: [],
                scanners: [],
                severity_levels: approval_rule.severity_levels,
                type: "scan_finding",
                vulnerabilities_allowed: approval_rule.vulnerabilities_allowed,
                vulnerability_states: approval_rule.vulnerability_states
              }
            ],
            description:
              "This security approval policy was auto-generated based on the previous vulnerability check rule.",
            enabled: true,
            name: "Vulnerability Check"
          }
        end

        before do
          group.add_owner(current_user)
        end

        shared_examples 'access token clean up' do
          it 'revokes the access token' do
            subject

            expect(PersonalAccessToken.first.revoked).to be true
          end
        end

        context 'with security_orchestration_policies feature not available' do
          let(:security_policies_enabled) { false }

          include_examples 'deletes the rule and logs warning',
            "with security_orchestration_policies not available for this license"
        end

        context 'when resource access token service fails' do
          let(:token_response) { { status: :error } }

          before do
            allow_next_instance_of(::ResourceAccessTokens::CreateService) do |resource_service|
              allow(resource_service).to receive(:execute).and_return(token_response)
            end
          end

          include_examples 'deletes the rule and logs warning', "with Failed to create access token: {:status=>:error}"
        end

        context 'when project creation service fails' do
          let(:project_create_reponse) { { status: :error } }

          before do
            allow_next_instance_of(::Security::SecurityOrchestrationPolicies::ProjectCreateService) do |service|
              allow(service).to receive(:execute).and_return(project_create_reponse)
            end
          end

          include_examples 'access token clean up'

          include_examples 'deletes the rule and logs warning',
            "with Failed to create orchestration project: {:status=>:error}"
        end

        context 'when policy commit service fails' do
          let(:policy_commit_response) { { status: :error } }

          before do
            allow_next_instance_of(::Security::SecurityOrchestrationPolicies::PolicyCommitService) do |service|
              allow(service).to receive(:execute).and_return(policy_commit_response)
            end
          end

          include_examples 'access token clean up'

          include_examples 'deletes the rule and logs warning', "with Failed to create commit: {:status=>:error}"
        end

        it 'updates approval rule' do
          expect(Gitlab::AppLogger).not_to receive(:warn)

          subject

          expect(approval_rule.reload.scan_finding?).to be(true)
        end

        it 'creates and assigns a security orchestration project' do
          expect(Gitlab::AppLogger).not_to receive(:warn)

          subject

          policy_configuration = project.reload.security_orchestration_policy_configuration

          expect(policy_configuration.security_policy_management_project).to be_present
        end

        it 'creates a new scan result policy' do
          expect(Gitlab::AppLogger).not_to receive(:warn)

          subject

          policy_configuration = project.reload.security_orchestration_policy_configuration

          expect(policy_configuration.active_scan_result_policies).to eq([expected_policy])
        end

        include_examples 'access token clean up'

        context 'with existing security orchestration project' do
          let_it_be(:policies_project) { create(:project, :repository, group: group) }
          let_it_be(:security_orchestration_policy_configuration) do
            create(:security_orchestration_policy_configuration,
              project: project,
              security_policy_management_project: policies_project)
          end

          context 'when policy commit service fails' do
            let(:policy_commit_response) { { status: :error } }

            before do
              allow_next_instance_of(::Security::SecurityOrchestrationPolicies::PolicyCommitService) do |service|
                allow(service).to receive(:execute).and_return(policy_commit_response)
              end
            end

            include_examples 'access token clean up'

            include_examples 'deletes the rule and logs warning', "with Failed to create commit: {:status=>:error}"
          end

          context 'when it fails to create a MR' do
            let(:merge_request_reponse) { instance_double(MergeRequest, persisted?: false) }

            before do
              allow(merge_request_reponse).to receive_message_chain(:errors, :messages)
              allow_next_instance_of(MergeRequests::CreateService) do |merge_request_service|
                allow(merge_request_service).to receive(:execute).and_return(merge_request_reponse)
              end
            end

            include_examples 'access token clean up'

            include_examples 'deletes the rule and logs warning', "with Failed to create merge request: "
          end

          it 'deletes the approval rule' do
            expect(Gitlab::AppLogger).not_to receive(:warn)
            expect(approval_rule.vulnerability?).to be(true)
            expect { subject }.to change(ApprovalProjectRule, :count).from(1).to(0)
          end

          it 'creates a merge request for the new scan result policy' do
            expect { subject }.to change {MergeRequest.count}.by(1)
          end

          it 'does not create a new security orchestration project' do
            expect(Gitlab::AppLogger).not_to receive(:warn)

            subject

            policy_configuration = project.reload.security_orchestration_policy_configuration

            expect(policy_configuration.security_policy_management_project).to eq(policies_project)
          end

          include_examples 'access token clean up'
        end
      end
    end
  end
end
