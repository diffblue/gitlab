# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Security::PoliciesController, type: :request do
  let_it_be(:owner) { create(:user) }
  let_it_be(:user) { create(:user) }
  let_it_be(:project, reload: true) { create(:project, namespace: owner.namespace) }

  before do
    project.add_developer(user)
    login_as(user)
  end

  context 'displaying page' do
    using RSpec::Parameterized::TableSyntax

    where(:feature_flag, :license, :status) do
      true | true | :ok
      false | false | :not_found
      false | true | :not_found
      true | false | :not_found
    end

    subject { get project_security_policy_url(project) }

    with_them do
      before do
        stub_feature_flags(security_orchestration_policies_configuration: feature_flag)
        stub_licensed_features(security_orchestration_policies: license)
      end

      specify do
        get project_security_policy_url(project)

        expect(response).to have_gitlab_http_status(status)
      end
    end
  end
end
