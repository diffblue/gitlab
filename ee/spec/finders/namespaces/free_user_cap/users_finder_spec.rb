# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::FreeUserCap::UsersFinder, feature_category: :experimentation_conversion do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, namespace: group) }
  let_it_be(:invited_group) { create(:group) }

  let(:limit) { 10 }

  before_all do
    group.add_developer(create(:user))
    project.add_developer(create(:user))
    group.add_guest(create(:user))
    project.add_guest(create(:user))
    invited_group.add_developer(create(:user))
    group.add_maintainer(create(:user, :project_bot))
    project.add_maintainer(create(:user, :project_bot))
    create(:group_group_link, { shared_with_group: invited_group, shared_group: group })
    create(:project_group_link, project: project, group: invited_group)
  end

  describe '#count' do
    it 'provides number of users' do
      instance = described_class.new(group, limit)
      instance.execute

      expect(instance.count)
        .to eq({
                 group_member_user_ids: 2,
                 project_member_user_ids: 2,
                 shared_group_user_ids: 1,
                 shared_project_user_ids: 1,
                 user_ids: 5
               })
    end
  end

  describe '.count' do
    it 'provides number of users' do
      expect(described_class.count(group, limit))
        .to eq({
                 group_member_user_ids: 2,
                 project_member_user_ids: 2,
                 shared_group_user_ids: 1,
                 shared_project_user_ids: 1,
                 user_ids: 5
               })
    end

    context 'with limit considerations that affect query invocation', :aggregate_failures do
      context 'when limit is reached and all queries are not needed' do
        it 'only performs group_member query' do
          expect(group).to receive(:billed_group_users).and_call_original
          expect(group).not_to receive(:billed_project_users)
          expect(group).not_to receive(:billed_shared_group_users)
          expect(group).not_to receive(:billed_invited_group_to_project_users)

          expect(described_class.count(group, 1)).to eq({ group_member_user_ids: 1, user_ids: 1 })
        end

        it 'only performs group_member and project_member queries' do
          expect(group).to receive(:billed_group_users).and_call_original
          expect(group).to receive(:billed_project_users).and_call_original
          expect(group).not_to receive(:billed_shared_group_users)
          expect(group).not_to receive(:billed_invited_group_to_project_users)

          expect(described_class.count(group, 3))
            .to eq({
                     group_member_user_ids: 2,
                     project_member_user_ids: 2,
                     user_ids: 4
                   })
        end

        it 'performs all queries except invited groups to projects' do
          expect(group).to receive(:billed_group_users).and_call_original
          expect(group).to receive(:billed_project_users).and_call_original
          expect(group).to receive(:billed_shared_group_users).and_call_original
          expect(group).not_to receive(:billed_invited_group_to_project_users)

          expect(described_class.count(group, 5))
            .to eq({
                     group_member_user_ids: 2,
                     project_member_user_ids: 2,
                     shared_group_user_ids: 1,
                     user_ids: 5
                   })
        end
      end

      context 'when limit is not reached until the last query' do
        it 'performs all queries' do
          project_invited_group = create(:group)
          project_invited_group.add_developer(create(:user))
          create(:project_group_link, project: project, group: project_invited_group)

          expect(group).to receive(:billed_group_users).and_call_original
          expect(group).to receive(:billed_project_users).and_call_original
          expect(group).to receive(:billed_shared_group_users).and_call_original
          expect(group).to receive(:billed_invited_group_to_project_users).and_call_original

          expect(described_class.count(group, 6))
            .to eq({
                     group_member_user_ids: 2,
                     project_member_user_ids: 2,
                     shared_group_user_ids: 1,
                     shared_project_user_ids: 2,
                     user_ids: 6
                   })
        end
      end
    end
  end
end
