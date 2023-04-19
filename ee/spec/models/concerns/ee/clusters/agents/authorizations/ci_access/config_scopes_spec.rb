# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::Clusters::Agents::Authorizations::CiAccess::ConfigScopes, feature_category: :deployment_management do
  describe '.with_available_ci_access_fields' do
    let_it_be(:project) { create(:project) }

    let_it_be(:agent_authorization_0)     { create(:agent_ci_access_project_authorization, project: project) }
    let_it_be(:agent_authorization_1)     { create(:agent_ci_access_project_authorization, project: project, config: { access_as: {} }) }
    let_it_be(:agent_authorization_2)     { create(:agent_ci_access_project_authorization, project: project, config: { access_as: { agent: {} } }) }
    let_it_be(:impersonate_authorization) { create(:agent_ci_access_project_authorization, project: project, config: { access_as: { impersonate: {} } }) }
    let_it_be(:ci_user_authorization)     { create(:agent_ci_access_project_authorization, project: project, config: { access_as: { ci_user: {} } }) }
    let_it_be(:ci_job_authorization)      { create(:agent_ci_access_project_authorization, project: project, config: { access_as: { ci_job: {} } }) }

    subject { Clusters::Agents::Authorizations::CiAccess::ProjectAuthorization.with_available_ci_access_fields(project) }

    it { is_expected.not_to include(ci_job_authorization) }
    it { is_expected.not_to include(ci_user_authorization) }
    it { is_expected.not_to include(impersonate_authorization) }

    context 'with :cluster_agents_ci_impersonation' do
      before do
        stub_licensed_features(cluster_agents_ci_impersonation: true)
      end

      it { is_expected.to include(ci_job_authorization, ci_user_authorization, impersonate_authorization) }
    end
  end
end
