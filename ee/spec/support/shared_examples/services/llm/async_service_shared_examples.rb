# frozen_string_literal: true

RSpec.shared_examples 'completion worker sync and async' do
  let(:resonse_double) { instance_double(Gitlab::Llm::BaseResponseModifier, response_body: "response") }
  let(:expected_options) { options.merge(request_id: 'uuid') }

  before do
    allow(SecureRandom).to receive(:uuid).and_return('uuid')
  end

  context 'when enabling sync execution via environment variables' do
    before do
      stub_env('LLM_DEVELOPMENT_SYNC_EXECUTION', true)
    end

    it 'runs worker synchronously' do
      expect_next_instance_of(Llm::CompletionWorker) do |worker|
        expect(worker).to receive(:perform).with(
          user.id, resource.id, resource.class.name, action_name, hash_including(**expected_options)
        ).and_return(resonse_double)
      end

      expect(subject.execute).to be_success
    end
  end

  context 'when running asynchronously' do
    before do
      allow(::Llm::CompletionWorker).to receive(:perform_async)
    end

    it 'worker runs asynchronously with correct params' do
      expect(::Llm::CompletionWorker)
        .to receive(:perform_async)
        .with(user.id, resource.id, resource.class.name, action_name, hash_including(**expected_options))

      expect(subject.execute).to be_success
    end
  end
end
