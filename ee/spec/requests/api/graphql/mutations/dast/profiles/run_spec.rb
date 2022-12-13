# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Running a DAST Profile', feature_category: :dynamic_application_security_testing do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:dast_profile) { create(:dast_profile, project: project) }

  let(:mutation_name) { :dast_profile_run }

  let(:mutation) do
    graphql_mutation(mutation_name, id: global_id_of(dast_profile))
  end

  it_behaves_like 'an on-demand scan mutation when user cannot run an on-demand scan'

  it_behaves_like 'an on-demand scan mutation when user can run an on-demand scan' do
    it 'returns a pipeline_url containing the correct path' do
      post_graphql_mutation(mutation, current_user: current_user)
      pipeline = Ci::Pipeline.last
      expected_url = Gitlab::Routing.url_helpers.project_pipeline_url(
        project,
        pipeline
      )

      expect(mutation_response['pipelineUrl']).to eq(expected_url)
    end

    context 'when pipeline creation fails' do
      let(:fake_pipeline) { instance_double('Ci::Pipeline', created_successfully?: false, full_error_messages: 'full error messages') }
      let(:fake_service) { instance_double('Ci::CreatePipelineService', execute: ServiceResponse.error(message: 'error message', payload: fake_pipeline)) }

      before do
        allow(Ci::CreatePipelineService).to receive(:new).and_return(fake_service)
      end

      it_behaves_like 'a mutation that returns errors in the response', errors: ['full error messages']
    end
  end
end
