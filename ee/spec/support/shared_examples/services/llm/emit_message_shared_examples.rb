# frozen_string_literal: true

RSpec.shared_examples 'service emitting message for user prompt' do
  let(:expected_subscription_params) do
    { request_id: anything, role: 'user', content: content, timestamp: an_instance_of(ActiveSupport::TimeWithZone) }
  end

  it 'triggers graphql subscription message' do
    allow(::Llm::CompletionWorker).to receive(:perform_async)

    expect(GraphqlTriggers).to receive(:ai_completion_response)
      .with(user.to_global_id, resource.to_global_id, expected_subscription_params)

    subject.execute
  end
end

RSpec.shared_examples 'service not emitting message for user prompt' do
  it 'does not trigger graphql subscription message' do
    allow(::Llm::CompletionWorker).to receive(:perform_async)

    expect(GraphqlTriggers).not_to receive(:ai_completion_response)

    subject.execute
  end
end
