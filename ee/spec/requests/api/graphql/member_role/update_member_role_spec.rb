# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting iterations', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:member_role) { create(:member_role, namespace: group) }
  let_it_be(:current_user) { create(:user) }

  let(:name) { 'new name' }
  let(:input) { { 'name' => name } }
  let(:mutation) { graphql_mutation(:memberRoleUpdate, input.merge('id' => member_role.to_global_id.to_s), fields) }
  let(:fields) do
    <<~FIELDS
      errors
      memberRole {
        id
        name
        description
      }
    FIELDS
  end

  subject(:update_member_role) { graphql_mutation_response(:member_role_update) }

  context 'without the custom roles feature' do
    before do
      stub_licensed_features(custom_roles: false)
    end

    context 'with owner role' do
      before_all do
        group.add_owner(current_user)
      end

      it_behaves_like 'a mutation that returns a top-level access error'
    end
  end

  context 'with the custom roles feature' do
    before do
      stub_licensed_features(custom_roles: true)
    end

    context 'with maintainer role' do
      before_all do
        group.add_maintainer(current_user)
      end

      it_behaves_like 'a mutation that returns a top-level access error'
    end

    context 'with owner role' do
      before_all do
        group.add_owner(current_user)
      end

      context 'with valid arguments' do
        it 'returns success' do
          post_graphql_mutation(mutation, current_user: current_user)

          expect(graphql_errors).to be_nil
          expect(update_member_role['memberRole']).to include('name' => 'new name')
        end

        it 'updates the member role' do
          expect { post_graphql_mutation(mutation, current_user: current_user) }
            .to change { member_role.reload.name }.to('new name')
        end
      end

      context 'with invalid arguments' do
        let(:name) { nil }

        it 'returns an error' do
          post_graphql_mutation(mutation, current_user: current_user)

          expect(update_member_role['errors'].first).to include("Name can't be blank")
          expect(update_member_role['memberRole']).not_to be_nil
        end
      end

      context 'with missing arguments' do
        let(:input) { {} }

        it 'returns an error' do
          post_graphql_mutation(mutation, current_user: current_user)

          expect(graphql_errors).not_to be_empty
          expect(graphql_errors.first['message'])
            .to include("The list of member_role attributes is empty")
        end
      end
    end
  end
end
