# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BilledUsersFinder do
  let_it_be_with_refind(:group) { create(:group) }

  let(:search_term) { nil }
  let(:order_by) { nil }
  let(:include_awaiting_members) { false }

  subject(:execute) { described_class.new(group, search_term: search_term, order_by: order_by, include_awaiting_members: include_awaiting_members).execute }

  describe '#execute' do
    context 'without members' do
      let(:include_awaiting_members) { true }

      it 'returns an empty object' do
        expect(execute).to eq({})
      end
    end

    context 'with members' do
      let_it_be(:maria) { create(:group_member, group: group, user: create(:user, name: 'Maria Gomez')) }
      let_it_be(:john_smith) { create(:group_member, group: group, user: create(:user, name: 'John Smith')) }
      let_it_be(:john_doe) { create(:group_member, group: group, user: create(:user, name: 'John Doe')) }
      let_it_be(:sophie) { create(:group_member, group: group, user: create(:user, name: 'Sophie Dupont')) }
      let_it_be(:alice_awaiting) { create(:group_member, :awaiting, :developer, group: group, user: create(:user, name: 'Alice Waiting')) }

      shared_examples 'with awaiting members' do
        context 'when awaiting users are included' do
          let(:include_awaiting_members) { true }

          it 'includes awaiting users' do
            expect(execute[:users]).to include(alice_awaiting.user)
          end
        end

        context 'when awaiting users are excluded' do
          let(:include_awaiting_members) { false }

          it 'excludes awaiting users' do
            expect(execute[:users]).not_to include(alice_awaiting.user)
          end
        end
      end

      context 'when user is awaiting and active member' do
        let_it_be(:project) { create(:project, group: group) }

        let(:include_awaiting_members) { true }

        before do
          create(:project_member, :maintainer, user: alice_awaiting.user, source: project)
        end

        it 'is only included once' do
          expect(execute[:users]).to include(alice_awaiting.user).once
        end
      end

      it_behaves_like 'with awaiting members'

      context 'when a search parameter is provided' do
        let(:search_term) { 'John' }

        context 'when a sorting parameter is provided (eg name descending)' do
          let(:order_by) { 'name_desc' }

          it 'sorts results accordingly' do
            expect(execute[:users]).to eq([john_smith, john_doe].map(&:user))
          end
        end

        context 'when a sorting parameter is not provided' do
          subject(:execute) { described_class.new(group, search_term: search_term).execute }

          it 'sorts expected results in name_asc order' do
            expect(execute[:users]).to eq([john_doe, john_smith].map(&:user))
          end
        end

        context 'when searching for an awaiting user' do
          let(:search_term) { 'Alice' }

          it_behaves_like 'with awaiting members'
        end
      end

      context 'when a search parameter is not present' do
        subject(:execute) { described_class.new(group, include_awaiting_members: include_awaiting_members).execute }

        it 'returns expected users in name asc order when a sorting is not provided either' do
          expect(execute[:users]).to eq([john_doe, john_smith, maria, sophie].map(&:user))
        end

        it_behaves_like 'with awaiting members'

        context 'and when a sorting parameter is provided (eg name descending)' do
          let(:order_by) { 'name_desc' }

          subject(:execute) { described_class.new(group, search_term: search_term, order_by: order_by, include_awaiting_members: include_awaiting_members).execute }

          it 'sorts results accordingly' do
            expect(execute[:users]).to eq([sophie, maria, john_smith, john_doe].map(&:user))
          end

          context 'when awaiting users are included' do
            let(:include_awaiting_members) { true }

            it 'sorts results accordingly' do
              expect(execute[:users]).to eq([sophie, maria, john_smith, john_doe, alice_awaiting].map(&:user))
            end
          end
        end
      end

      context 'with billable group members including shared members' do
        let_it_be(:shared_with_group_member) { create(:group_member, user: create(:user, name: 'Shared Group User')) }
        let_it_be(:shared_with_project_member) { create(:group_member, user: create(:user, name: 'Shared Project User')) }
        let_it_be(:project) { create(:project, group: group) }

        before do
          create(:group_group_link, shared_group: group, shared_with_group: shared_with_group_member.group)
          create(:project_group_link, group: shared_with_project_member.group, project: project)
        end

        it 'returns a hash of users and user ids' do
          expect(execute.keys).to eq([
            :users,
            :group_member_user_ids,
            :project_member_user_ids,
            :shared_group_user_ids,
            :shared_project_user_ids,
            :awaiting_user_ids
          ])
        end

        it 'returns the correct user ids', :aggregate_failures do
          expect(execute[:group_member_user_ids]).to contain_exactly(*[maria, john_smith, john_doe, sophie].map(&:user_id))
          expect(execute[:shared_group_user_ids]).to contain_exactly(shared_with_group_member.user_id)
          expect(execute[:shared_project_user_ids]).to contain_exactly(shared_with_project_member.user_id)
        end
      end
    end
  end
end
