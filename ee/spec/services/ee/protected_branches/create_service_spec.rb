# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProtectedBranches::CreateService, feature_category: :compliance_management do
  include ProjectForksHelper

  let(:source_project) { create(:project) }
  let(:target_project) { fork_project(source_project, user, repository: true) }
  let(:security_orchestration_policy_configuration) do
    create(:security_orchestration_policy_configuration, project: target_project)
  end

  let(:user) { source_project.first_owner }

  let(:params) do
    {
      name: "feature",
      merge_access_levels_attributes: [{ access_level: Gitlab::Access::MAINTAINER }],
      push_access_levels_attributes: [{ access_level: Gitlab::Access::MAINTAINER }]
    }
  end

  describe "#execute" do
    subject(:service) { described_class.new(target_project, user, params) }

    before do
      target_project.add_member(user, :developer)
    end

    context "code_owner_approval_required" do
      context "when unavailable" do
        before do
          stub_licensed_features(code_owner_approval_required: false)

          params[:code_owner_approval_required] = true
        end

        it "ignores incoming params and sets code_owner_approval_required to false", :aggregate_failures do
          expect { service.execute }.to change(ProtectedBranch, :count).by(1)
          expect(ProtectedBranch.last.code_owner_approval_required).to be_falsy
        end
      end

      context "when available" do
        before do
          stub_licensed_features(code_owner_approval_required: true)
          params[:code_owner_approval_required] = code_owner_approval_required
        end

        context "when code_owner_approval_required param is true" do
          let(:code_owner_approval_required) { true }

          it "sets code_owner_approval_required to true", :aggregate_failures do
            expect { service.execute }.to change(ProtectedBranch, :count).by(1)
            expect(ProtectedBranch.last.code_owner_approval_required).to be_truthy
          end

          it_behaves_like 'records an onboarding progress action', :code_owners_enabled do
            let(:namespace) { target_project.namespace }

            subject { service.execute }
          end
        end

        context "when code_owner_approval_required param is false" do
          let(:code_owner_approval_required) { false }

          it "sets code_owner_approval_required to false", :aggregate_failures do
            expect { service.execute }.to change(ProtectedBranch, :count).by(1)
            expect(ProtectedBranch.last.code_owner_approval_required).to be_falsy
          end

          it_behaves_like 'does not record an onboarding progress action'
        end
      end
    end

    context 'when security_orchestration_policies is not licensed' do
      before do
        stub_licensed_features(security_orchestration_policies: false)
        allow(target_project).to receive(:all_security_orchestration_policy_configurations)
          .and_return([security_orchestration_policy_configuration])
      end

      it 'does not sync scan_finding_approval_rules' do
        expect(Security::SecurityOrchestrationPolicies::SyncScanResultPoliciesService).not_to receive(:new)
        expect(Security::SecurityOrchestrationPolicies::SyncScanResultPoliciesProjectService).not_to receive(:new)

        service.execute
      end
    end

    context 'when security_orchestration_policies is licensed' do
      before do
        stub_licensed_features(security_orchestration_policies: true)
        allow(target_project).to receive(:all_security_orchestration_policy_configurations)
          .and_return([security_orchestration_policy_configuration])
      end

      it 'syncs scan_finding_approval_rules' do
        expect_next_instance_of(
          Security::SecurityOrchestrationPolicies::SyncScanResultPoliciesProjectService,
          security_orchestration_policy_configuration
        ) do |sync_service|
          expect(sync_service).to receive(:execute).with(target_project.id)
        end

        service.execute
      end
    end

    context "when there are open merge requests" do
      let!(:merge_request) do
        create(:merge_request,
          source_project: source_project,
          target_project: target_project,
          discussion_locked: false
        )
      end

      it "calls MergeRequest::SyncCodeOwnerApprovalRules to update open MRs", :aggregate_failures do
        expect(::MergeRequests::SyncCodeOwnerApprovalRules).to receive(:new).with(merge_request).and_call_original
        expect { service.execute }.to change(ProtectedBranch, :count).by(1)
      end

      context "when the branch is a wildcard" do
        %w(*ture *eatur* feat*).each do |wildcard|
          context "with wildcard: #{wildcard}" do
            before do
              params[:name] = wildcard
            end

            it "calls MergeRequest::SyncCodeOwnerApprovalRules to update open MRs", :aggregate_failures do
              expect(::MergeRequests::SyncCodeOwnerApprovalRules).to receive(:new).with(merge_request).and_call_original
              expect { service.execute }.to change(ProtectedBranch, :count).by(1)
            end
          end
        end
      end
    end

    it 'adds a security audit event entry' do
      expect { service.execute }.to change(::AuditEvent, :count).by(1)
    end

    context 'with invalid params' do
      let(:params) { nil }

      it "doesn't add a security audit event entry" do
        expect { service.execute }.not_to change(::AuditEvent, :count)
      end
    end
  end

  context 'when entity group' do
    let_it_be_with_reload(:entity) { create(:group) }
    let_it_be_with_reload(:user) { create(:user) }
    let_it_be_with_reload(:security_orchestration_policy_configuration) do
      create(:security_orchestration_policy_configuration, :namespace, namespace: entity)
    end

    let(:service) { described_class.new(entity, user) }

    before do
      entity.add_owner(user)
    end

    it 'return early in `sync_code_owner_approval_rules`' do
      expect(service).to receive(:sync_code_owner_approval_rules)
      expect(entity).not_to receive(:merge_requests)

      service.execute
    end

    it 'return early in `track_onboarding_progress`' do
      expect(service).to receive(:track_onboarding_progress)
      expect(Onboarding::ProgressService).not_to receive(:new)

      service.execute
    end

    context 'when security_orchestration_policies is not licensed' do
      before do
        stub_licensed_features(security_orchestration_policies: false)
        allow(entity).to receive(:all_security_orchestration_policy_configurations)
          .and_return([security_orchestration_policy_configuration])
      end

      it 'does not sync scan_finding_approval_rules' do
        expect(Security::SecurityOrchestrationPolicies::SyncScanResultPoliciesService).not_to receive(:new)

        service.execute
      end
    end

    context 'when security_orchestration_policies is licensed' do
      before do
        stub_licensed_features(security_orchestration_policies: true)
        allow(entity).to receive(:all_security_orchestration_policy_configurations)
          .and_return([security_orchestration_policy_configuration])
      end

      it 'syncs scan_finding_approval_rules' do
        expect_next_instance_of(
          Security::SecurityOrchestrationPolicies::SyncScanResultPoliciesService,
          security_orchestration_policy_configuration
        ) do |sync_service|
          expect(sync_service).to receive(:execute).with(no_args)
        end

        service.execute
      end
    end
  end
end
