# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Creating a DAST Site Token', feature_category: :dynamic_application_security_testing do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:uuid) { '0000-0000-0000-0000' }

  let(:mutation_name) { :dast_site_token_create }

  let(:mutation) do
    graphql_mutation(
      mutation_name,
      full_path: full_path,
      target_url: generate(:url)
    )
  end

  before do
    allow(SecureRandom).to receive(:uuid).and_return(uuid)
  end

  it_behaves_like 'an on-demand scan mutation when user cannot run an on-demand scan'

  it_behaves_like 'an on-demand scan mutation when user can run an on-demand scan' do
    it 'returns the dast_site_token id' do
      subject

      dast_site_token = DastSiteToken.find_by!(project: project, token: uuid)

      expect(mutation_response).to match a_graphql_entity_for(dast_site_token)
    end

    it 'creates a new dast_site_token' do
      expect { subject }.to change { DastSiteToken.count }.by(1)
    end
  end
end
