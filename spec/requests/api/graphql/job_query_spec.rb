# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting job information' do
  include GraphqlHelpers

  let_it_be(:job) { create(:ci_build, name: 'job1') }

  let(:query) do
    graphql_query_for(:jobs)
  end

  context 'when user is admin' do
    let_it_be(:current_user) { create(:admin) }

    it 'has full access to all jobs' do
      post_graphql(query, current_user: current_user)

      expect(graphql_data['jobs']['nodes'].first["name"]).to match("job1")
      expect(graphql_data['jobs']['count']).to match(1)
    end
  end

  context 'if the user is not an admin' do
    let_it_be(:current_user) { create(:user) }

    it 'has no access to the jobs' do
      post_graphql(query, current_user: current_user)

      expect(graphql_data['jobs']['nodes']).to match([])
      expect(graphql_data['jobs']['count']).to match(0)
    end
  end
end
