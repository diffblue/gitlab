# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::BilledUsersFinder, feature_category: :purchase do
  describe '#execute' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, namespace: group) }
    let_it_be(:group_developer) { group.add_developer(create(:user)).user }
    let_it_be(:project_developer) { project.add_developer(create(:user)).user }
    let_it_be(:group_guest) { group.add_guest(create(:user)).user }
    let_it_be(:project_guest) { project.add_guest(create(:user)).user }
    let_it_be(:invited_group) { create(:group) }
    let_it_be(:invited_developer) { invited_group.add_developer(create(:user)).user }

    before_all do
      group.add_maintainer(create(:user, :project_bot))
      project.add_maintainer(create(:user, :project_bot))
      create(:group_group_link, { shared_with_group: invited_group, shared_group: group })
      create(:project_group_link, project: project, group: invited_group)
    end

    subject(:billed_user_ids) { described_class.new(group).execute }

    it 'returns a breakdown of billable user ids' do
      expect(billed_user_ids.keys).to eq([
                                           :user_ids,
                                           :group_member_user_ids,
                                           :project_member_user_ids,
                                           :shared_group_user_ids,
                                           :shared_project_user_ids
                                         ])
    end

    context 'when including guests' do
      it 'includes distinct active users' do
        expect(billed_user_ids[:user_ids]).to match_array([
                                                            group_guest.id,
                                                            project_guest.id,
                                                            group_developer.id,
                                                            project_developer.id,
                                                            invited_developer.id
                                                          ])
        expect(billed_user_ids[:group_member_user_ids]).to match_array([group_guest.id, group_developer.id])
        expect(billed_user_ids[:project_member_user_ids]).to match_array([project_guest.id, project_developer.id])
        expect(billed_user_ids[:shared_group_user_ids]).to match_array([invited_developer.id])
        expect(billed_user_ids[:shared_project_user_ids]).to match_array([invited_developer.id])
      end
    end

    context 'when excluding guests' do
      subject(:billed_user_ids) { described_class.new(group, exclude_guests: true).execute }

      it 'includes distinct active users' do
        expect(billed_user_ids[:user_ids])
          .to match_array([group_developer.id, project_developer.id, invited_developer.id])
        expect(billed_user_ids[:group_member_user_ids]).to match_array([group_developer.id])
        expect(billed_user_ids[:project_member_user_ids]).to match_array([project_developer.id])
        expect(billed_user_ids[:shared_group_user_ids]).to match_array([invited_developer.id])
        expect(billed_user_ids[:shared_project_user_ids]).to match_array([invited_developer.id])
      end
    end
  end
end
