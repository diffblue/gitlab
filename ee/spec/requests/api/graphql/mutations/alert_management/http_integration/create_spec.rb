# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Creating a new HTTP Integration', feature_category: :incident_management do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }

  let(:payload_example) do
    {
      'tool' => %w[DataDog V1],
      'alert' => { 'name' => 'Test alert' },
      'started_at' => Time.current.strftime('%d %B %Y, %-l:%M%p (%Z)')
    }.to_json
  end

  let(:payload_attribute_mappings) do
    [
      { fieldName: 'TITLE', path: %w[alert name], type: 'STRING' },
      { fieldName: 'START_TIME', path: %w[started_at], type: 'DATETIME', label: 'Start time' },
      { fieldName: 'MONITORING_TOOL', path: ['tool', 0], type: 'STRING', label: 'Tool[0]' },
      { fieldName: 'HOSTS', path: %w[tool], type: 'ARRAY', label: 'Tool' }
    ]
  end

  let(:variables) do
    {
      project_path: project.full_path,
      active: false,
      name: 'New HTTP Integration',
      payload_example: payload_example,
      payload_attribute_mappings: payload_attribute_mappings
    }
  end

  let(:mutation) do
    graphql_mutation(:http_integration_create, variables) do
      <<~QL
         clientMutationId
         errors
         integration {
           id
           type
           name
           active
           token
           url
           apiUrl
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

  let(:mutation_response) { graphql_mutation_response(:http_integration_create) }

  shared_examples 'ignoring the custom mapping' do
    it 'creates integration without the custom mapping params' do
      post_graphql_mutation(mutation, current_user: current_user)

      new_integration = ::AlertManagement::HttpIntegration.last!
      integration_response = mutation_response['integration']

      expect(response).to have_gitlab_http_status(:success)
      expect(integration_response['id']).to eq(GitlabSchema.id_from_object(new_integration).to_s)
      expect(new_integration.payload_example).to eq({})
      expect(new_integration.payload_attribute_mapping).to eq({})
      expect(integration_response['payloadExample']).to eq('{}')
      expect(integration_response['payloadAttributeMappings']).to be_empty
    end
  end

  before do
    project.add_maintainer(current_user)

    stub_licensed_features(multiple_alert_http_integrations: true)
  end

  it_behaves_like 'creating a new HTTP integration'

  it 'stores the custom mapping params' do
    post_graphql_mutation(mutation, current_user: current_user)

    new_integration = ::AlertManagement::HttpIntegration.last!
    integration_response = mutation_response['integration']

    expect(new_integration.payload_example).to eq(Gitlab::Json.parse(payload_example))
    expect(new_integration.payload_attribute_mapping).to eq(
      {
        'title' => { 'path' => %w[alert name], 'type' => 'string', 'label' => nil },
        'start_time' => { 'path' => %w[started_at], 'type' => 'datetime', 'label' => 'Start time' },
        'monitoring_tool' => { 'path' => ['tool', 0], 'type' => 'string', 'label' => 'Tool[0]' },
        'hosts' => { 'path' => %w[tool], 'type' => 'array', 'label' => 'Tool' }
      }
    )
    expect(integration_response['payloadExample']).to eq(payload_example)
    expect(integration_response['payloadAttributeMappings']).to match_array(
      [
        { 'fieldName' => 'TITLE', 'path' => %w[alert name], 'type' => 'STRING', 'label' => nil },
        { 'fieldName' => 'START_TIME', 'path' => %w[started_at], 'type' => 'DATETIME', 'label' => 'Start time' },
        { 'fieldName' => 'MONITORING_TOOL', 'path' => ['tool', 0], 'type' => 'STRING', 'label' => 'Tool[0]' },
        { 'fieldName' => 'HOSTS', 'path' => %w[tool], 'type' => 'ARRAY', 'label' => 'Tool' }
      ]
    )
  end

  [:project_path, :active, :name].each do |argument|
    context "without required argument #{argument}" do
      before do
        variables.delete(argument)
      end

      it_behaves_like 'an invalid argument to the mutation', argument_name: argument
    end
  end

  context 'with the custom mappings feature unavailable' do
    before do
      stub_licensed_features(multiple_alert_http_integrations: false)
    end

    it_behaves_like 'ignoring the custom mapping'
  end

  it_behaves_like 'validating the payload_example'
  it_behaves_like 'validating the payload_attribute_mappings'
end
