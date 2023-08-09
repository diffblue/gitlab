# frozen_string_literal: true

RSpec.shared_examples 'completion worker sync and async' do
  let(:expected_subscription_params) do
    { request_id: 'uuid', role: 'user', content: content, timestamp: an_instance_of(ActiveSupport::TimeWithZone) }
  end

  before do
    allow(SecureRandom).to receive(:uuid).and_return('uuid')
  end

  context 'when running synchronously' do
    before do
      options[:sync] = true
    end

    it 'worker runs synchronously' do
      expected_options = options.merge(request_id: 'uuid')

      expect_next_instance_of(Llm::CompletionWorker) do |worker|
        expect(worker).to receive(:perform).with(
          user.id, resource.id, resource.class.name, action_name, expected_options
        ).and_return({})
      end

      expect(subject.execute).to be_success
    end
  end

  context 'when running asynchronously' do
    before do
      options[:sync] = false
      allow(::Llm::CompletionWorker).to receive(:perform_async)
    end

    it 'worker runs asynchronously with correct params' do
      expected_options = options.merge(request_id: 'uuid')

      expect(::Llm::CompletionWorker)
        .to receive(:perform_async)
        .with(user.id, resource.id, resource.class.name, action_name, expected_options)

      expect(subject.execute).to be_success
    end

    it 'triggers graphql subscription message' do
      expect(GraphqlTriggers).to receive(:ai_completion_response)
        .with(user.to_global_id, resource.to_global_id, expected_subscription_params)

      subject.execute
    end
  end
end
