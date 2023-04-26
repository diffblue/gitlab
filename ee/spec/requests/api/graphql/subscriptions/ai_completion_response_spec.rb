# frozen_string_literal: true

require "spec_helper"

RSpec.describe 'Subscriptions::AiCompletionResponse', feature_category: :not_owned do # rubocop: disable RSpec/InvalidFeatureCategory
  include GraphqlHelpers
  include Graphql::Subscriptions::Notes::Helper

  let_it_be(:guest) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:resource) { create(:work_item, :task, project: project) }

  let(:current_user) { nil }
  let(:subscribe) { get_subscription(resource, current_user) }
  let(:ai_completion_response) { graphql_dig_at(graphql_data(response[:result]), :ai_completion_response) }

  before do
    stub_const('GitlabSchema', Graphql::Subscriptions::ActionCable::MockGitlabSchema)
    Graphql::Subscriptions::ActionCable::MockActionCable.clear_mocks
    project.add_guest(guest)
  end

  subject(:response) do
    subscription_response do
      data = {
        id: SecureRandom.uuid,
        model_name: resource.class.name,
        response_body: "Some AI response",
        errors: []
      }

      GraphqlTriggers.ai_completion_response(current_user&.to_gid, resource.to_gid, data)
    end
  end

  context 'when user is nil' do
    it 'does not receive any data' do
      expect(response).to be_nil
    end
  end

  context 'when user is unauthorized' do
    let(:current_user) { create(:user) }

    it 'does not receive any data' do
      expect(response).to be_nil
    end
  end

  context 'when user is authorized' do
    let(:current_user) { guest }

    it 'receives data' do
      expect(ai_completion_response['responseBody']).to eq("Some AI response")
      expect(ai_completion_response['errors']).to eq([])
    end
  end

  def get_subscription(resource, current_user)
    mock_channel = Graphql::Subscriptions::ActionCable::MockActionCable.get_mock_channel
    query = ai_completion_subscription_query(current_user, resource)

    GitlabSchema.execute(query, context: { current_user: current_user, channel: mock_channel })

    mock_channel
  end

  def ai_completion_subscription_query(user, resource)
    <<~SUBSCRIPTION
      subscription {
        aiCompletionResponse(userId:\"#{user&.to_gid}\", resourceId: \"#{resource.to_gid}\") {
          responseBody
          errors
        }
      }
    SUBSCRIPTION
  end
end
