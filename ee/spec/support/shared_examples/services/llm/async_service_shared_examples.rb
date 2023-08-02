# frozen_string_literal: true

RSpec.shared_examples 'completion worker sync and async' do
  let(:expected_cache_params) do
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

    it 'caches request' do
      expect_next_instance_of(::Gitlab::Llm::Cache) do |cache|
        expect(cache).to receive(:add).with(expected_cache_params)
      end

      subject.execute
    end

    it 'triggers graphql subscription message' do
      expect(GraphqlTriggers).to receive(:ai_completion_response)
        .with(user.to_global_id, resource.to_global_id, expected_cache_params)

      subject.execute
    end

    context 'when ai_chat_emit_user_messages is disabled' do
      before do
        stub_feature_flags(ai_chat_emit_user_messages: false)
      end

      it 'does not trigger graphql subscription message' do
        expect(GraphqlTriggers).not_to receive(:ai_completion_response)

        subject.execute
      end
    end

    context 'when a special reset message is used' do
      let(:content) { '/reset' }

      before do
        allow(subject).to receive(:content).and_return(content)
      end

      it 'only stores the message in cache' do
        expect(::Llm::CompletionWorker).not_to receive(:perform_async)

        expect_next_instance_of(::Gitlab::Llm::Cache) do |cache|
          expect(cache).to receive(:add).with(expected_cache_params)
        end

        subject.execute
      end
    end
  end
end
