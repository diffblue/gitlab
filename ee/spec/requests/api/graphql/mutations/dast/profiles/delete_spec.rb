# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Deleting a DAST Profile', feature_category: :dynamic_application_security_testing do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:dast_profile) { create(:dast_profile, project: project) }

  let(:mutation_name) { :dast_profile_delete }
  let(:mutation) { graphql_mutation(mutation_name, id: global_id_of(dast_profile)) }

  it_behaves_like 'an on-demand scan mutation when user cannot run an on-demand scan'

  it_behaves_like 'an on-demand scan mutation when user can run an on-demand scan' do
    it 'deletes the dast_profile' do
      expect { subject }.to change { Dast::Profile.count }.by(-1)
    end
  end
end
