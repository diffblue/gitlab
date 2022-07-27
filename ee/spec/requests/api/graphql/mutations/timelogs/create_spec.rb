# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Create a timelog' do
  include GraphqlHelpers

  let_it_be(:author) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:time_spent) { '1h' }

  let(:current_user) { nil }
  let(:users_container) { group }
  let(:mutation) do
    graphql_mutation(:timelogCreate, {
      'time_spent' => time_spent,
      'spent_at' => '2022-07-08',
      'summary' => 'Test summary',
      'issuable_id' => issuable.to_global_id.to_s
    })
  end

  let(:mutation_response) { graphql_mutation_response(:timelog_create) }

  context 'when issuable is an Epic' do
    let_it_be(:issuable) { create(:epic, group: group) }

    it_behaves_like 'issuable does not support timelog creation mutation'
  end
end
