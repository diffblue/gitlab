# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::AppSec::Fuzzing::API::CiConfiguration::Create do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  let(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }

  before_all do
    project.add_developer(user)
  end

  describe '#resolve' do
    subject do
      mutation.resolve(
        api_specification_file: 'https://api.gov/api_spec',
        auth_password: '$PASSWORD',
        auth_username: '$USERNAME',
        project_path: project.full_path,
        scan_mode: :har,
        scan_profile: 'Quick-10',
        target: 'https://api.gov'
      )
    end

    context 'when the user can access the API fuzzing configuration feature' do
      before do
        stub_licensed_features(security_dashboard: true)
      end

      it 'returns a YAML snippet that can be used to configure API fuzzing scans for the project' do
        aggregate_failures do
          expect(subject[:errors]).to be_empty
          expect(subject[:gitlab_ci_yaml_edit_path]).to eq(
            Rails.application.routes.url_helpers.project_ci_pipeline_editor_path(project)
          )
          expect(Psych.load(subject[:configuration_yaml])).to eq({
            'stages' => ['fuzz'],
            'include' => [{ 'template' => 'Security/API-Fuzzing.gitlab-ci.yml' }],
            'variables' => {
              'FUZZAPI_HTTP_PASSWORD' => '$PASSWORD',
              'FUZZAPI_HTTP_USERNAME' => '$USERNAME',
              'FUZZAPI_HAR' => 'https://api.gov/api_spec',
              'FUZZAPI_PROFILE' => 'Quick-10',
              'FUZZAPI_TARGET_URL' => 'https://api.gov'
            }
          })
        end
      end

      context 'when the user cannot access the API fuzzing configuration feature' do
        before do
          stub_licensed_features(security_dashboard: false)
        end

        it 'returns an authentication error' do
          expect { subject }.to raise_error(
            ::Gitlab::Graphql::Errors::ResourceNotAvailable,
            'The resource that you are attempting to access does not exist '\
            "or you don't have permission to perform this action"
          )
        end
      end
    end
  end
end
