# frozen_string_literal: true

require "spec_helper"

RSpec.describe ProjectTeam do
  let(:group) { create(:group) }
  let(:project) { create(:project, group: group) }

  describe '#add_members' do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }

    context 'when group membership is locked' do
      before do
        group.update_attribute(:membership_lock, true)
      end

      it 'does not add the given users to the team' do
        project.team.add_members([user1, user2], :reporter)

        expect(project.team.reporter?(user1)).to be(false)
        expect(project.team.reporter?(user2)).to be(false)
      end
    end
  end

  describe '#add_member' do
    let(:user) { create(:user) }

    context 'when group membership is locked' do
      before do
        group.update_attribute(:membership_lock, true)
      end

      it 'does not add the given user to the team' do
        project.team.add_member(user, :reporter)

        expect(project.members.map(&:user)).not_to include(user)
      end

      context 'project bot user' do
        let_it_be(:project_bot) { create(:user, :project_bot) }

        it 'adds the project bot user to the team' do
          project.team.add_member(project_bot, :maintainer)

          expect(project.members.map(&:user)).to include(project_bot)
        end
      end
    end
  end
end
