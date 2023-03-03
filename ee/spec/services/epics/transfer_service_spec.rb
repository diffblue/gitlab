# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Epics::TransferService, feature_category: :portfolio_management do
  describe '#execute' do
    let_it_be(:user) { create(:user) }
    let_it_be(:new_group, refind: true) { create(:group) }
    let_it_be(:old_group, refind: true) { create(:group) }

    before do
      old_group.add_maintainer(user) if old_group
    end

    subject(:service) { described_class.new(user, old_group, project) }

    context 'when old_group is present' do
      let_it_be(:project) { create(:project, namespace: old_group) }
      let_it_be(:epic) { create(:epic, group: old_group, title: 'Epic 1') }
      let_it_be(:other_epic) { create(:epic, group: old_group, title: 'Epic 2') }
      let_it_be(:issue1_with_epic) { create(:issue, project: project, epic: epic) }
      let_it_be(:issue2_with_epic) { create(:issue, project: project, epic: epic) }
      let_it_be(:issue_with_other_epic) { create(:issue, project: project, epic: other_epic) }

      let(:new_epic) { issue1_with_epic.reload.epic }

      before do
        stub_licensed_features(epics: true)
        project.add_maintainer(user)
        # simulate project transfer
        project.update!(group: new_group)
      end

      context 'when user can create epics in the new group' do
        before do
          new_group.add_maintainer(user)
        end

        it 'recreates the missing group epics in the new group' do
          expect { service.execute }.to change(project.group.epics, :count).by(2)

          expect(new_epic).not_to eq(epic)
          expect(new_epic).to eq(issue2_with_epic.reload.epic)
          expect(new_epic.group).to eq(new_group)
          expect(new_epic.title).to eq(epic.title)
          expect(new_epic.description).to eq(epic.description)
          expect(new_epic.start_date).to eq(epic.start_date)
          expect(new_epic.end_date).to eq(epic.end_date)
          expect(new_epic.confidential).to eq(epic.confidential)
        end

        it 'does not recreate missing epics that are not applied to issues' do
          unassigned_epic = create(:epic, group: old_group)
          service.execute

          new_epics_titles = project.group.reload.epics.pluck(:title)

          expect(new_epics_titles).to include(epic.title).and exclude(unassigned_epic.title)
        end

        context 'when rate limiting is in effect', :freeze_time, :clean_gitlab_redis_rate_limiting do
          before do
            stub_application_setting(issues_create_limit: 1)
          end

          it 'transfers both epics' do
            expect { service.execute }.to change(project.group.epics, :count).by(2)
          end
        end

        context 'when epic is from an descendant group' do
          let_it_be(:old_group_subgroup) { create(:group, parent: old_group) }

          it 'recreates the missing epic in the new group' do
            create(:epic, group: old_group_subgroup)

            expect { service.execute }.to change(project.group.epics, :count).by(2)
          end
        end

        context 'when epic is from an ascending group' do
          let_it_be(:new_group) { create(:group, parent: old_group) }

          it 'does not recreate the epics in the new group' do
            expect { service.execute }.not_to change(new_group.epics, :count)
          end
        end

        context 'when create_epic returns nil' do
          before do
            allow_next_instance_of(Epics::CreateService) do |instance|
              allow(instance).to receive(:execute).and_return(nil)
            end
          end

          it 'removes issues epic' do
            service.execute

            expect(issue1_with_epic.reload.epic).to be_nil
            expect(issue2_with_epic.reload.epic).to be_nil
          end
        end

        context 'when assigned epic is confidential' do
          before do
            [issue1_with_epic, issue2_with_epic, epic].each { |issuable| issuable.update!(confidential: true) }
          end

          it 'creates a new confidential epic in the new group' do
            expect { service.execute }.to change(project.group.epics, :count).by(2)

            expect(new_epic).not_to eq(epic.group)
            expect(new_epic.title).to eq(epic.title)
            expect(new_epic.confidential).to be_truthy
          end
        end
      end

      context 'when user is a guest of the new group' do
        let_it_be(:guest) { create(:user) }

        before do
          old_group.add_owner(guest)
          project.add_maintainer(user)
          new_group.add_guest(guest)
        end

        it 'does not create a new epic but removes assigned epic' do
          service = described_class.new(guest, old_group, project)

          expect { service.execute }.not_to change(project.group.epics, :count)
          expect(issue1_with_epic.reload.epic).to be_nil
          expect(issue2_with_epic.reload.epic).to be_nil
        end
      end

      context 'when epics are disabled' do
        before do
          stub_licensed_features(epics: false)
        end

        it 'does not create a new epic' do
          expect { service.execute }.not_to change(project.group.epics, :count)
        end
      end
    end

    context 'when old_group is not present' do
      let_it_be(:project) { create(:project, namespace: create(:namespace)) }
      let_it_be(:old_group) { nil }

      before do
        project.update!(namespace: new_group)
      end

      it 'returns nil' do
        expect(described_class.new(user, old_group, project).execute).to be_nil
      end
    end

    context 'when project group is not present' do
      let_it_be(:project) { create(:project, group: old_group) }

      before do
        project.update!(namespace: user.namespace)
      end

      it 'returns nil' do
        expect(described_class.new(user, old_group, project).execute).to be_nil
      end
    end
  end
end
