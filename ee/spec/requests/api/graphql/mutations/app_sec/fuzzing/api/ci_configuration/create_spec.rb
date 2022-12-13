# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'CreateApiFuzzingCiConfiguration', feature_category: :fuzz_testing do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  let(:mutation) do
    %(
      mutation {
        apiFuzzingCiConfigurationCreate(input: {
          apiSpecificationFile: "https://api.gov/api_spec",
          authPassword: "$PASSWORD",
          authUsername: "$USERNAME",
          projectPath: "#{project.full_path}",
          scanMode: OPENAPI,
          scanProfile: "Quick-10",
          target: "https://api.gov"
        }) {
          configurationYaml
          errors
          gitlabCiYamlEditPath
        }
      }
    )
  end

  before_all do
    project.add_developer(user)
  end

  before do
    stub_licensed_features(security_dashboard: true)
  end

  it 'returns a YAML snippet that can be used to configure API fuzzing scans for the project' do
    post_graphql(mutation, current_user: user)

    expect(response).to have_gitlab_http_status(:ok)
    expect(graphql_errors).to be_nil

    mutation_response = graphql_mutation_response(:api_fuzzing_ci_configuration_create)
    yaml = mutation_response['configurationYaml']
    gitlab_ci_yml_edit_path = mutation_response['gitlabCiYamlEditPath']
    errors = mutation_response['errors']

    aggregate_failures do
      expect(errors).to be_empty
      expect(gitlab_ci_yml_edit_path).to eq(project_ci_pipeline_editor_path(project))
      expect(Psych.load(yaml)).to eq({
        'stages' => ['fuzz'],
        'include' => [{ 'template' => 'Security/API-Fuzzing.gitlab-ci.yml' }],
        'variables' => {
          'FUZZAPI_HTTP_PASSWORD' => '$PASSWORD',
          'FUZZAPI_HTTP_USERNAME' => '$USERNAME',
          'FUZZAPI_OPENAPI' => 'https://api.gov/api_spec',
          'FUZZAPI_PROFILE' => 'Quick-10',
          'FUZZAPI_TARGET_URL' => 'https://api.gov'
        }
      })
    end
  end
end
