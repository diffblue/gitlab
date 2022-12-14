# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.gitlabSubscriptionsPreviewBillableUserChange', feature_category: :purchase do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:fields) { 'willIncreaseOverage newBillableUserCount seatsInSubscription' }
  let_it_be(:base_args) { { role: :DEVELOPER } }

  shared_examples 'preview billable user change' do
    context 'when project_or_group does not exist' do
      let(:full_path) { 'non_existent_path' }
      let(:args) { base_args.merge(add_user_ids: [1]) }

      it 'returns nil' do
        post_graphql(query, current_user: current_user)

        expect(subject).to be nil
      end
    end

    context 'when project_or_group exists' do
      context 'when current_user has access to project_or_group' do
        before do
          project_or_group.root_ancestor.add_owner(current_user)
        end

        context 'with add_group_id' do
          let(:add_group) { create(:group) }
          let(:args) { base_args.merge(add_group_id: add_group.id) }

          it 'returns successfully' do
            post_graphql(query, current_user: current_user)

            expect(subject).to eq(
              {
                'willIncreaseOverage' => false,
                'newBillableUserCount' => 1,
                'seatsInSubscription' => 0
              }
            )
          end
        end

        context 'with add_user_emails' do
          let(:args) { base_args.merge(add_user_emails: ['foo@example.com']) }

          it 'returns successfully' do
            post_graphql(query, current_user: current_user)

            expect(subject).to eq(
              {
                'willIncreaseOverage' => true,
                'newBillableUserCount' => 2,
                'seatsInSubscription' => 0
              }
            )
          end
        end

        context 'with add_user_ids' do
          let(:args) { base_args.merge(add_user_ids: [1]) }

          it 'returns successfully' do
            post_graphql(query, current_user: current_user)

            expect(subject).to eq(
              {
                'willIncreaseOverage' => true,
                'newBillableUserCount' => 2,
                'seatsInSubscription' => 0
              }
            )
          end
        end

        context 'when missing all add_* arguments' do
          let(:args) { base_args }

          it 'returns error' do
            post_graphql(query, current_user: current_user)

            expect_graphql_errors_to_include(
              'Must provide "addUserIds", "addUserEmails" or "addGroupId" argument'
            )
          end
        end
      end

      context 'when current_user does not have access to project_or_group' do
        let(:args) { base_args.merge(add_user_ids: [1]) }

        it 'returns error' do
          post_graphql(query, current_user: current_user)

          expect_graphql_errors_to_include("you don't have permission")
        end
      end
    end
  end

  context 'with group query' do
    let(:query) do
      graphql_query_for(
        'group',
        { 'fullPath' => full_path },
        query_graphql_field('gitlabSubscriptionsPreviewBillableUserChange', args, fields)
      )
    end

    let_it_be(:project_or_group) { create(:group) }
    let_it_be(:full_path) { project_or_group.full_path }

    subject { graphql_data.dig('group', 'gitlabSubscriptionsPreviewBillableUserChange') }

    it_behaves_like 'preview billable user change'
  end

  context 'with project query' do
    let(:query) do
      graphql_query_for(
        'project',
        { 'fullPath' => full_path },
        query_graphql_field('gitlabSubscriptionsPreviewBillableUserChange', args, fields)
      )
    end

    let_it_be(:project_or_group) { create(:project, :in_subgroup) }
    let_it_be(:full_path) { project_or_group.full_path }

    before do
      project_or_group.add_guest(current_user)
    end

    subject { graphql_data.dig('project', 'gitlabSubscriptionsPreviewBillableUserChange') }

    it_behaves_like 'preview billable user change'
  end
end
