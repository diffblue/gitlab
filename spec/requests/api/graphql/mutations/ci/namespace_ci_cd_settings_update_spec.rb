# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'NamespaceCiCdSettingsUpdate' do
  include GraphqlHelpers

  let_it_be(:namespace) do
    create(:group, :public).tap(&:save!)
  end

  let(:variables) do
    {
      full_path: namespace.full_path
    }
  end

  let(:mutation) { graphql_mutation(:namespace_ci_cd_settings_update, variables) }

  context 'when unauthorized' do
    let(:user) { create(:user) }

    shared_examples 'unauthorized' do
      it 'returns an error' do
        post_graphql_mutation(mutation, current_user: user)

        expect(graphql_errors).not_to be_empty
      end
    end

    context 'when not a namespace member' do
      it_behaves_like 'unauthorized'
    end

    context 'when a non-admin namespace member' do
      before do
        namespace.add_developer(user)
      end

      it_behaves_like 'unauthorized'
    end
  end

  context 'when authorized' do
    let_it_be(:user) { create(:user) }

    before do
      namespace.add_owner(user)
    end

    it 'returns :success' do
      post_graphql_mutation(mutation, current_user: user)

      namespace.reload

      expect(response).to have_gitlab_http_status(:success)
    end

    context 'when bad arguments are provided' do
      let(:variables) { { full_path: '' } }

      it 'returns the errors' do
        post_graphql_mutation(mutation, current_user: user)

        expect(graphql_errors).not_to be_empty
      end
    end
  end
end
