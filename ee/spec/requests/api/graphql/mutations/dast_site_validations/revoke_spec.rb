# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Creating a DAST Site Token', feature_category: :dynamic_application_security_testing do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:dast_site_token) { create(:dast_site_token, project: project) }
  let_it_be(:dast_site_validation) { create(:dast_site_validation, state: :passed, dast_site_token: dast_site_token) }

  let(:mutation_name) { :dast_site_validation_revoke }

  let(:mutation) do
    graphql_mutation(
      mutation_name,
      full_path: project.full_path,
      normalized_target_url: dast_site_validation.url_base
    )
  end

  it_behaves_like 'an on-demand scan mutation when user cannot run an on-demand scan'

  it_behaves_like 'an on-demand scan mutation when user can run an on-demand scan' do
    it 'deletes dast_site_validations where state=passed' do
      expect { subject }.to change { DastSiteValidation.count }.from(1).to(0)
    end
  end
end
