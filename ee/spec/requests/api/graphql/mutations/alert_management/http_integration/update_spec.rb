# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Updating an existing HTTP Integration', feature_category: :incident_management do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:integration) { create(:alert_management_http_integration, project: project) }

  let(:payload_example) do
    {
      'alert' => { 'name' => 'Test alert' },
      'started_at' => Time.current.strftime('%d %B %Y, %-l:%M%p (%Z)')
    }.to_json
  end

  let(:payload_attribute_mappings) do
    [
      { fieldName: 'TITLE', path: %w[alert name], type: 'STRING' },
      { fieldName: 'START_TIME', path: %w[started_at], type: 'DATETIME', label: 'Start time' }
    ]
  end

  let(:mutation) do
    variables = {
      id: GitlabSchema.id_from_object(integration).to_s,
      name: 'Modified Name',
      active: false,
      payload_example: payload_example,
      payload_attribute_mappings: payload_attribute_mappings
    }
    graphql_mutation(:http_integration_update, variables) do
      <<~QL
        clientMutationId
        errors
        integration {
          id
          name
          active
          url
          payloadExample
          payloadAttributeMappings {
            fieldName
            path
            label
            type
          }
        }
      QL
    end
  end

  let(:mutation_response) { graphql_mutation_response(:http_integration_update) }

  shared_examples 'ignoring the custom mapping' do
    it 'updates integration without the custom mapping params', :aggregate_failures do
      post_graphql_mutation(mutation, current_user: current_user)

      integration.reload
      integration_response = mutation_response['integration']

      expect(response).to have_gitlab_http_status(:success)
      expect(integration.payload_example).to eq({})
      expect(integration.payload_attribute_mapping).to eq({})
      expect(integration_response['payloadExample']).to eq('{}')
      expect(integration_response['payloadAttributeMappings']).to be_empty
    end
  end

  before do
    project.add_maintainer(current_user)

    stub_licensed_features(multiple_alert_http_integrations: true)
  end

  it_behaves_like 'updating an existing HTTP integration'
  it_behaves_like 'validating the payload_example'
  it_behaves_like 'validating the payload_attribute_mappings'

  it 'updates the custom mapping params', :aggregate_failures do
    post_graphql_mutation(mutation, current_user: current_user)

    integration.reload
    integration_response = mutation_response['integration']

    expect(response).to have_gitlab_http_status(:success)
    expect(integration.payload_example).to eq(Gitlab::Json.parse(payload_example))
    expect(integration.payload_attribute_mapping).to eq(
      'start_time' => {
        'label' => 'Start time',
        'path' => %w[started_at],
        'type' => 'datetime'
      },
      'title' => {
        'label' => nil,
        'path' => %w[alert name],
        'type' => 'string'
      }
    )
    expect(integration_response['payloadExample']).to eq(payload_example)
    expect(integration_response['payloadAttributeMappings']).to eq(
      [
        { 'fieldName' => 'TITLE', 'path' => %w[alert name], 'type' => 'STRING', 'label' => nil },
        { 'fieldName' => 'START_TIME', 'path' => %w[started_at], 'type' => 'DATETIME', 'label' => 'Start time' }
      ]
    )
  end

  context 'when the integration already has custom mapping params' do
    let_it_be(:current_payload_example) do
      { 'alert' => { 'name' => 'Test alert', 'desc' => 'Description' } }
    end

    let_it_be(:current_mapping) do
      {
        'title' => { 'path' => %w(alert name), 'type' => 'string', 'label' => 'Title' },
        'description' => { 'path' => %w(alert desc), 'type' => 'string' }
      }
    end

    let_it_be(:integration) do
      create(:alert_management_http_integration, project: project, payload_example: current_payload_example, payload_attribute_mapping: current_mapping)
    end

    context 'when the custom mappings attributes are blank' do
      let(:payload_example) { "{}" }
      let(:payload_attribute_mappings) { [] }

      it 'resets the custom mapping params', :aggregate_failures do
        post_graphql_mutation(mutation, current_user: current_user)

        integration_response = mutation_response['integration']

        expect(response).to have_gitlab_http_status(:success)
        expect(integration_response['id']).to eq(GitlabSchema.id_from_object(integration).to_s)
        expect(integration_response['name']).to eq('Modified Name')
        expect(integration_response['payloadExample']).to eq('{}')
        expect(integration_response['payloadAttributeMappings']).to be_empty
      end
    end

    context 'when the custom mappings attributes are nils' do
      let(:payload_example) { nil }
      let(:payload_attribute_mappings) { nil }

      it 'resets the custom mapping params', :aggregate_failures do
        post_graphql_mutation(mutation, current_user: current_user)

        integration_response = mutation_response['integration']

        expect(response).to have_gitlab_http_status(:success)
        expect(integration_response['id']).to eq(GitlabSchema.id_from_object(integration).to_s)
        expect(integration_response['name']).to eq('Modified Name')
        expect(integration_response['payloadExample']).to eq('{}')
        expect(integration_response['payloadAttributeMappings']).to be_empty
      end
    end

    context 'when the custom mappings attributes are not part of the mutation variables' do
      let(:mutation) do
        variables = {
          id: GitlabSchema.id_from_object(integration).to_s,
          name: 'Modified Name'
        }
        graphql_mutation(:http_integration_update, variables) do
          <<~QL
            clientMutationId
            errors
            integration {
              id
              name
              payloadExample
              payloadAttributeMappings {
                fieldName
              }
            }
          QL
        end
      end

      it 'does not reset the custom mapping attributes', :aggregate_failures do
        post_graphql_mutation(mutation, current_user: current_user)

        integration_response = mutation_response['integration']

        expect(response).to have_gitlab_http_status(:success)
        expect(integration_response['id']).to eq(GitlabSchema.id_from_object(integration).to_s)
        expect(integration_response['name']).to eq('Modified Name')
        expect(integration_response['payloadExample']).not_to eq('{}')
        expect(integration_response['payloadAttributeMappings']).to be_present

        integration.reload
        expect(integration.payload_example).to eq(current_payload_example)
        expect(integration.payload_attribute_mapping).to eq(current_mapping)
      end
    end
  end

  context 'with the custom mappings feature unavailable' do
    before do
      stub_licensed_features(multiple_alert_http_integrations: false)
    end

    it_behaves_like 'ignoring the custom mapping'
  end
end
