# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Update a compliance framework', feature_category: :compliance_management do
  include GraphqlHelpers

  let_it_be(:namespace) { create(:group) }
  let_it_be(:framework) { create(:compliance_framework, namespace: namespace) }

  let(:current_user) { create(:user) }
  let(:mutation) { graphql_mutation(:update_compliance_framework, { id: global_id_of(framework), **params }) }
  let(:params) do
    {
      params: {
        name: 'New Name',
        description: 'New Description',
        color: '#AAC112'
      }
    }
  end

  subject { post_graphql_mutation(mutation, current_user: current_user) }

  before do
    namespace.add_owner(current_user)
  end

  def mutation_response
    graphql_mutation_response(:update_compliance_framework)
  end

  context 'feature is unlicensed' do
    before do
      stub_licensed_features(custom_compliance_frameworks: false)
    end

    it_behaves_like 'a mutation that returns top-level errors',
                    errors: [Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR]
  end

  context 'feature is licensed but disabled' do
    before do
      stub_licensed_features(custom_compliance_frameworks: false)
    end

    it_behaves_like 'a mutation that returns top-level errors',
                    errors: [Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR]
  end

  context 'feature is licensed' do
    before do
      stub_licensed_features(custom_compliance_frameworks: true)
    end

    context 'with valid params' do
      it 'returns an empty array of errors' do
        subject

        expect(mutation_response['errors']).to be_empty
      end

      it 'returns the updated framework', :aggregate_failures do
        subject

        expect(mutation_response['complianceFramework']['name']).to eq 'New Name'
        expect(mutation_response['complianceFramework']['description']).to eq 'New Description'
        expect(mutation_response['complianceFramework']['color']).to eq '#AAC112'
      end

      context 'pipeline configuration full path' do
        before do
          params[:params][:pipeline_configuration_full_path] = '.compliance-gitlab-ci.yml@compliance/hipaa'
        end

        context 'when compliance pipeline configuration feature is available' do
          before do
            stub_licensed_features(custom_compliance_frameworks: true, evaluate_group_level_compliance_pipeline: true)
          end

          it 'updates the pipeline configuration path attribute' do
            subject

            expect(mutation_response['complianceFramework']['pipelineConfigurationFullPath']).to eq '.compliance-gitlab-ci.yml@compliance/hipaa'
          end
        end

        context 'when compliance pipeline configuration feature is not available' do
          before do
            stub_licensed_features(custom_compliance_frameworks: true, evaluate_group_level_compliance_pipeline: false)
          end

          it 'returns an error' do
            subject

            expect(mutation_response['errors']).to contain_exactly "Pipeline configuration full path feature is not available"
          end
        end
      end

      context 'current_user is not permitted to update framework' do
        before do
          namespace.update!(owners: [])
        end

        it_behaves_like 'a mutation that returns top-level errors',
                        errors: [Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR]
      end
    end

    context 'with invalid params' do
      let(:params) do
        {
          params: {
            name: '',
            description: '',
            color: 'NOTACOLOR'
          }
        }
      end

      it 'returns an array of errors' do
        subject

        expect(mutation_response['errors']).to contain_exactly "Color must be a valid color code", "Description can't be blank", "Name can't be blank"
      end

      it 'does not update the framework' do
        expect { subject }.not_to change { framework.name }
        expect { subject }.not_to change { framework.description }
        expect { subject }.not_to change { framework.color }
      end
    end
  end
end
