# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::DestroyService, feature_category: :subgroups do
  let(:current_user) { create(:user) }
  let(:member_user) { create(:user) }
  let(:group) { create(:group) }
  let(:member) { group.members.find_by(user_id: member_user.id) }

  before do
    group.add_owner(current_user)
    group.add_developer(member_user)
  end

  shared_examples_for 'logs an audit event' do
    specify do
      expect(::Gitlab::Audit::Auditor).to receive(:audit).with(
        hash_including(name: "member_destroyed")
      ).and_call_original

      expect { event }.to change { AuditEvent.count }.by(1)
    end
  end

  context 'when current_user is present' do
    subject { described_class.new(current_user) }

    context 'with group membership via Group SAML' do
      let!(:saml_provider) { create(:saml_provider, group: group) }

      context 'with a SAML identity' do
        before do
          create(:group_saml_identity, user: member_user, saml_provider: saml_provider)
        end

        it 'cleans up linked SAML identity' do
          expect { subject.execute(member) }.to change { member_user.reload.identities.count }.by(-1)
        end
      end

      context 'without a SAML identity' do
        it 'does not attempt to destroy unrelated identities' do
          create(:identity, user: member_user)

          expect { subject.execute(member) }.not_to change(Identity, :count)
        end
      end
    end

    context 'audit events' do
      it_behaves_like 'logs an audit event' do
        let(:event) { subject.execute(member) }
      end

      it 'does not log the audit event as a system event' do
        subject.execute(member, skip_authorization: true)
        details = AuditEvent.last.details

        expect(details[:system_event]).to be_nil
        expect(details[:reason]).to be_nil
      end
    end

    context 'streaming audit event' do
      subject { described_class.new(current_user).execute(member, skip_authorization: true) }

      it 'audits event with name' do
        expect(::Gitlab::Audit::Auditor).to receive(:audit).with(
          hash_including(name: "member_destroyed")
        ).and_call_original

        subject
      end

      include_examples 'sends streaming audit event'
    end

    context 'group deletion schedule' do
      context 'when member user has a scheduled deletion for the group' do
        let!(:group_deletion_schedule) { create(:group_deletion_schedule, group: group, user_id: member_user.id, marked_for_deletion_on: 2.days.ago) }

        it 'deletes the group deletion schedule' do
          expect(group.reload.deletion_schedule).to eq(group_deletion_schedule)

          subject.execute(member)

          expect(group.reload.deletion_schedule).to be nil
        end
      end

      context 'when scheduled deletion for the group belongs to different user' do
        let!(:group_deletion_schedule) { create(:group_deletion_schedule, group: group, user_id: current_user.id, marked_for_deletion_on: 2.days.ago) }

        it 'does not delete the group deletion schedule' do
          subject.execute(member)

          expect(group.reload.deletion_schedule).to eq(group_deletion_schedule)
        end
      end
    end

    context 'on-call rotations' do
      let!(:project) { create(:project, group: group) }

      context 'when member is in an on-call rotation' do
        let(:project_1_schedule) {  create(:incident_management_oncall_schedule, project: project) }
        let(:project_1_rotation) {  create(:incident_management_oncall_rotation, schedule: project_1_schedule) }
        let!(:project_1_participant) { create(:incident_management_oncall_participant, rotation: project_1_rotation, user: member_user) }

        let(:project_2) { create(:project, group: group) }
        let(:project_2_schedule) {  create(:incident_management_oncall_schedule, project: project_2) }
        let(:project_2_rotation) {  create(:incident_management_oncall_rotation, schedule: project_2_schedule) }
        let!(:project_2_participant) { create(:incident_management_oncall_participant, rotation: project_2_rotation, user: member_user) }

        context 'when group member is removed' do
          it 'calls the remove service for each project in the group' do
            expect(IncidentManagement::OncallRotations::RemoveParticipantsService).to receive(:new).with([project_1_rotation, project_2_rotation], member_user).and_call_original

            subject.execute(member)

            expect(project_1_participant.reload.is_removed).to eq(true)
            expect(project_2_participant.reload.is_removed).to eq(true)
          end
        end

        context 'when project member is removed' do
          let!(:project_member) { create(:project_member, source: project, user: member_user) }

          it 'calls the remove service for that project only' do
            expect(IncidentManagement::OncallRotations::RemoveParticipantsService).to receive(:new).with([project_1_rotation], member_user).and_call_original

            subject.execute(project_member)

            expect(project_1_participant.reload.is_removed).to eq(true)
            expect(project_2_participant.reload.is_removed).to eq(false)
          end
        end
      end

      context 'when member is not part of an on-call rotation for the group' do
        before do
          # Creates a rotation for another project in another group
          create(:incident_management_oncall_participant, user: member_user)
        end

        it 'does not call the remove service' do
          expect(IncidentManagement::OncallRotations::RemoveParticipantsService).not_to receive(:new)

          subject.execute(member)
        end
      end
    end

    context 'user escalation rules' do
      let(:project) { create(:project, group: group) }
      let(:project_2) { create(:project, group: group) }
      let(:project_1_policy) { create(:incident_management_escalation_policy, project: project) }
      let(:project_2_policy) { create(:incident_management_escalation_policy, project: project_2) }
      let!(:project_1_rule) { create(:incident_management_escalation_rule, :with_user, user: member_user, policy: project_1_policy) }
      let!(:project_2_rule) { create(:incident_management_escalation_rule, :with_user, user: member_user, policy: project_2_policy) }

      shared_examples_for 'calls the destroy service' do |scope, *rules|
        let(:rules_to_delete) { rules.map { |rule_name| send(rule_name) } }
        let(:rules_to_preserve) { IncidentManagement::EscalationRule.all - rules_to_delete }

        it "calls the destroy service #{scope}" do
          expect(IncidentManagement::EscalationRules::DestroyService)
            .to receive(:new)
            .with({ escalation_rules: rules_to_delete, user: member_user })
            .and_call_original

          subject.execute(member)

          rules_to_delete.each { |rule| expect { rule.reload }.to raise_error(ActiveRecord::RecordNotFound) }
          rules_to_preserve.each { |rule| expect { rule.reload }.not_to raise_error }
        end
      end

      context 'group member is removed' do
        let(:other_user) { create(:user, developer_projects: [group]) }
        let!(:other_user_rule) { create(:incident_management_escalation_rule, :with_user, user: other_user, policy: project_1_policy) }
        let!(:other_namespace_rule) { create(:incident_management_escalation_rule, :with_user, user: member_user) }

        include_examples 'calls the destroy service', 'with rules each project in the group', :project_1_rule, :project_2_rule
      end

      context 'project member is removed' do
        let!(:member) { create(:project_member, source: project, user: member_user) }

        include_examples 'calls the destroy service', 'with rules for the project', :project_1_rule
      end
    end

    context 'when user is a security_policy_bot' do
      let_it_be(:project) { create(:project) }
      let_it_be(:user) { create(:user, user_type: :security_policy_bot) }
      let_it_be(:member) { create(:project_member, user: user, project: project) }
      let_it_be(:security_orchestration_policy_configuration) { create(:security_orchestration_policy_configuration, bot_user: user) }

      before do
        project.add_owner(current_user)
      end

      it 'nullifies the configuration bot_user_id' do
        expect { subject.execute(member) }.to change { security_orchestration_policy_configuration.reload.bot_user_id }.to(nil)
      end
    end
  end

  context 'when current user is not present' do # ie, when the system initiates the destroy
    subject { described_class.new(nil) }

    context 'for members with expired access' do
      let!(:member) { create(:project_member, user: member_user, expires_at: 1.day.from_now) }

      before do
        travel_to(3.days.from_now)
      end

      context 'audit events' do
        it_behaves_like 'logs an audit event' do
          let(:event) { subject.execute(member, skip_authorization: true) }
        end

        it 'logs the audit event as a system event' do
          subject.execute(member, skip_authorization: true)
          details = AuditEvent.last.details

          expect(details[:system_event]).to be_truthy
          expect(details[:reason]).to include('access expired on')
        end
      end
    end
  end
end
