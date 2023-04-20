# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::TransferService do
  include EE::GeoHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :public) }

  let(:project) { create(:project, :repository, :public, :legacy_storage, namespace: user.namespace) }

  subject { described_class.new(project, user) }

  before do
    group.add_owner(user)
  end

  context 'when running on a primary node' do
    let_it_be(:primary) { create(:geo_node, :primary) }
    let_it_be(:secondary) { create(:geo_node) }

    it 'logs an event to the Geo event log' do
      stub_current_geo_node(primary)

      expect { subject.execute(group) }.to change(Geo::RepositoryRenamedEvent, :count).by(1)
    end
  end

  context 'audit events' do
    include_examples 'audit event logging' do
      let(:fail_condition!) do
        expect(project).to receive(:has_container_registry_tags?).and_return(true)

        def operation
          subject.execute(group)
        end
      end

      let(:attributes) do
        {
           author_id: user.id,
           entity_id: project.id,
           entity_type: 'Project',
           details: {
             change: 'namespace',
             from: project.old_path_with_namespace,
             to: project.full_path,
             author_name: user.name,
             author_class: user.class.name,
             target_id: project.id,
             target_type: 'Project',
             target_details: project.full_path,
             custom_message: "Changed namespace from #{project.old_path_with_namespace} to #{project.full_path}"
           }
         }
      end
    end
  end

  context 'missing epics applied to issues' do
    it 'delegates transfer to Epics::TransferService' do
      expect_next_instance_of(Epics::TransferService, user, project.group, project) do |epics_transfer_service|
        expect(epics_transfer_service).to receive(:execute).once.and_call_original
      end

      subject.execute(group)
    end
  end

  describe 'elasticsearch indexing' do
    it 'delegates transfer to Elastic::ProjectTransferWorker' do
      expect(::Elastic::ProjectTransferWorker).to receive(:perform_async).with(project.id, project.namespace.id, group.id).once

      subject.execute(group)
    end
  end

  describe 'security policy project' do
    context 'when project has policy project' do
      let!(:configuration) { create(:security_orchestration_policy_configuration, project: project) }

      it 'unassigns the policy project' do
        subject.execute(group)

        expect { configuration.reload }.to raise_exception(ActiveRecord::RecordNotFound)
      end
    end

    context 'when project has inherited policy project' do
      let_it_be(:group, reload: true) { create(:group) }
      let_it_be(:sub_group, reload: true) { create(:group, parent: group) }
      let_it_be(:group_configuration, reload: true) { create(:security_orchestration_policy_configuration, project: nil, namespace: group) }
      let_it_be(:sub_group_configuration, reload: true) { create(:security_orchestration_policy_configuration, project: nil, namespace: sub_group) }

      let!(:group_approval_rule) { create(:approval_project_rule, :scan_finding, :requires_approval, project: project, security_orchestration_policy_configuration: group_configuration) }
      let!(:sub_group_approval_rule) { create(:approval_project_rule, :scan_finding, :requires_approval, project: project, security_orchestration_policy_configuration: sub_group_configuration) }

      before do
        sub_group.add_owner(user)

        allow_next_found_instance_of(Security::OrchestrationPolicyConfiguration) do |configuration|
          allow(configuration).to receive(:policy_configuration_valid?).and_return(true)
        end
      end

      it 'deletes scan_finding_rules for inherited policy project' do
        subject.execute(sub_group)

        expect(project.approval_rules).to be_empty
        expect { group_approval_rule.reload }.to raise_exception(ActiveRecord::RecordNotFound)
        expect { sub_group_approval_rule.reload }.to raise_exception(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'updating paid features' do
    let(:premium_group) { create(:group_with_plan, plan: :premium_plan) }

    let_it_be(:free_group) { create(:group) }

    before do
      free_group.add_owner(user)
    end

    describe 'project access tokens' do
      before do
        ResourceAccessTokens::CreateService.new(user, project).execute
      end

      def revoked_tokens
        PersonalAccessToken.without_impersonation.for_users(project.bots).revoked
      end

      context 'with a self managed instance' do
        before do
          stub_ee_application_setting(should_check_namespace_plan: false)
        end

        it 'does not revoke PATs' do
          subject.execute(group)

          expect { subject.execute(group) }.not_to change { revoked_tokens.count }
        end
      end

      context 'with GL.com', :saas do
        before do
          premium_group.add_owner(user)
          stub_ee_application_setting(should_check_namespace_plan: true)
        end

        context 'when target namespace has a premium plan' do
          it 'does not revoke PATs' do
            expect { subject.execute(premium_group) }.not_to change { revoked_tokens.count }
          end
        end

        context 'when target namespace has a free plan' do
          it 'revoke PATs' do
            expect { subject.execute(free_group) }.to change { revoked_tokens.count }.from(0).to(1)
          end
        end
      end
    end

    describe 'pipeline subscriptions', :saas do
      let_it_be(:project_2) { create(:project, :public) }

      before do
        create(:license, plan: License::PREMIUM_PLAN)
        stub_ee_application_setting(should_check_namespace_plan: true)

        premium_group.add_owner(user)
      end

      context 'when target namespace has a premium plan' do
        it 'does not schedule cleanup for upstream project subscription' do
          expect(::Ci::UpstreamProjectsSubscriptionsCleanupWorker).not_to receive(:perform_async)

          subject.execute(premium_group)
        end
      end

      context 'when target namespace has a free plan' do
        it 'schedules cleanup for upstream project subscription' do
          expect(::Ci::UpstreamProjectsSubscriptionsCleanupWorker).to receive(:perform_async).with(project.id).and_call_original

          subject.execute(free_group)
        end
      end
    end

    describe 'test cases', :saas do
      before do
        create(:quality_test_case, project: project, author: user)
        stub_ee_application_setting(should_check_namespace_plan: true)
      end

      context 'when target namespace has a premium plan' do
        it 'does not delete the test cases' do
          subject.execute(premium_group)

          expect { subject.execute(premium_group) }.not_to change { project.issues.with_issue_type(:test_case).count }
        end
      end

      context 'when target namespace has a free plan' do
        it 'deletes the test cases' do
          expect { subject.execute(free_group) }.to change { project.issues.with_issue_type(:test_case).count }.from(1).to(0)
        end
      end
    end
  end

  describe 'deleting compliance framework setting' do
    context 'when the project has a compliance framework setting' do
      let!(:compliance_framework_setting) { create(:compliance_framework_project_setting, project: project) }

      it 'deletes the compliance framework setting' do
        expect { subject.execute(group) }.to change { ::ComplianceManagement::ComplianceFramework::ProjectSettings.count }.from(1).to(0)
      end
    end

    context 'when the project does not have a compliance framework setting' do
      it 'does not raise an error' do
        expect { subject.execute(group) }.not_to raise_error
      end

      it 'does not change the compliance framework settings count' do
        expect { subject.execute(group) }.not_to change { ::ComplianceManagement::ComplianceFramework::ProjectSettings.count }
      end
    end
  end
end
