# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'GroupMemberBulkUpdate', feature_category: :subgroups do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:group_member) { create(:group_member, :minimal_access, group: group, user: user) }
  let_it_be(:mutation_name) { :group_member_bulk_update }

  let(:input_params) do
    {
      'group_id' => group.to_global_id.to_s,
      'user_ids' => [user.to_global_id.to_s],
      'access_level' => 'GUEST'
    }
  end

  let(:mutation) { graphql_mutation(mutation_name, input_params) }
  let(:mutation_response) { graphql_mutation_response(mutation_name) }

  before do
    stub_licensed_features(minimal_access_role: true)
    group.add_owner(current_user)
  end

  it 'updates the members with minimal access' do
    post_graphql_mutation(mutation, current_user: current_user)

    new_access_level = mutation_response['groupMembers'].first['accessLevel']['integerValue']
    expect(response).to have_gitlab_http_status(:success)
    expect(mutation_response['errors']).to be_empty
    expect(new_access_level).to eq(Gitlab::Access::GUEST)
  end
end
