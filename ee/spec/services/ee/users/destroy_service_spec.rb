# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::DestroyService do
  let_it_be(:current_user) { create(:admin) }

  subject(:service) { described_class.new(current_user) }

  describe '#execute' do
    let!(:user) { create(:user) }

    subject(:operation) { service.execute(user) }

    context 'when admin mode is disabled' do
      it 'raises access denied' do
        expect { operation }.to raise_error(::Gitlab::Access::AccessDeniedError)
      end
    end

    context 'when admin mode is enabled', :enable_admin_mode do
      it 'returns result' do
        allow(user).to receive(:destroy).and_return(user)

        expect(operation).to eq(user)
      end

      context 'when project is a mirror' do
        let(:project) { create(:project, :mirror, mirror_user_id: user.id) }

        it 'disables mirror and does not assign a new mirror_user' do
          expect(::Gitlab::ErrorTracking).to receive(:track_exception)

          allow_next_instance_of(::NotificationService) do |notification|
            expect(notification).to receive(:mirror_was_disabled)
              .with(project, user.name)
              .and_call_original
          end

          expect { operation }.to change { project.reload.mirror_user }.from(user).to(nil)
            .and change { project.reload.mirror }.from(true).to(false)
        end
      end

      context 'migrating associated records' do
        context 'when hard_delete option is given' do
          let!(:resource_iteration_event) { create(:resource_iteration_event, user: user) }

          it 'will ghost certain records' do
            expect_any_instance_of(Users::MigrateToGhostUserService).to receive(:execute).once.and_call_original

            service.execute(user, hard_delete: true)

            expect(resource_iteration_event.reload.user).to be_ghost
          end
        end
      end

      context 'when user has oncall rotations' do
        let(:schedule) { create(:incident_management_oncall_schedule, project: project) }
        let(:rotation) { create(:incident_management_oncall_rotation, schedule: schedule) }
        let!(:participant) { create(:incident_management_oncall_participant, rotation: rotation, user: user) }
        let!(:other_participant) { create(:incident_management_oncall_participant, rotation: rotation) }

        context 'in their own project' do
          let(:project) { create(:project, namespace: user.namespace) }

          it 'deletes the project and the schedule' do
            operation

            expect { project.reload }.to raise_error(ActiveRecord::RecordNotFound)
            expect { schedule.reload }.to raise_error(ActiveRecord::RecordNotFound)
          end
        end

        context 'in a group project' do
          let(:group) { create(:group) }
          let(:project) { create(:project, namespace: group) }

          before do
            project.add_developer(user)
          end

          it 'deletes the participant from the rotation' do
            expect(rotation.participants.reload).to include(participant)

            operation

            expect(rotation.participants.reload).not_to include(participant)
          end

          it 'sends an email about the user being removed from the rotation' do
            expect { operation }.to change(ActionMailer::Base.deliveries, :size).by(1)
          end
        end
      end

      context 'when user has escalation rules' do
        let(:project) { create(:project) }
        let(:user) { project.first_owner }
        let(:project_policy) { create(:incident_management_escalation_policy, project: project) }
        let!(:project_rule) { create(:incident_management_escalation_rule, :with_user, policy: project_policy, user: user) }

        let(:group) { create(:group) }
        let(:group_project) { create(:project, group: group) }
        let(:group_policy) { create(:incident_management_escalation_policy, project: group_project) }
        let!(:group_rule) { create(:incident_management_escalation_rule, :with_user, policy: group_policy, user: user) }
        let!(:group_owner) { create(:user) }

        before do
          group.add_developer(user)
          group.add_owner(group_owner)
        end

        it 'deletes the escalation rules and notifies owners of group projects' do
          expect { operation }.to change(ActionMailer::Base.deliveries, :size).by(1)

          expect { project.reload }.to raise_error(ActiveRecord::RecordNotFound)
          expect { project_rule.reload }.to raise_error(ActiveRecord::RecordNotFound)
          expect { group_rule.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      describe 'audit events' do
        include_examples 'audit event logging' do
          let(:fail_condition!) do
            expect_any_instance_of(User)
              .to receive(:destroy).and_return(false)
          end

          let(:attributes) do
            {
              author_id: current_user.id,
              entity_id: @resource.id,
              entity_type: 'User',
              details: {
                remove: 'user',
                author_name: current_user.name,
                target_id: @resource.id,
                target_type: 'User',
                target_details: @resource.full_path
              }
            }
          end
        end
      end
    end
  end
end
