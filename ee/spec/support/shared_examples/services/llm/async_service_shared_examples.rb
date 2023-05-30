# frozen_string_literal: true

RSpec.shared_examples 'completion worker sync and async' do
  it 'worker runs asynchronously' do
    expected_options = options.merge(request_id: 'uuid')

    expect(SecureRandom).to receive(:uuid).twice.and_return('uuid')
    expect(::Llm::CompletionWorker)
      .to receive(:perform_async)
      .with(user.id, resource.id, resource.class.name, action_name, expected_options)

    expect(subject.execute).to be_success
  end

  context 'when running synchronously' do
    before do
      options.merge!(sync: true)
    end

    it 'worker runs synchronously' do
      expected_options = options.merge(request_id: 'uuid')

      expect(SecureRandom).to receive(:uuid).twice.and_return('uuid')
      expect_next_instance_of(Llm::CompletionWorker) do |worker|
        expect(worker).to receive(:perform).with(
          user.id, resource.id, resource.class.name, action_name, expected_options
        ).and_return({})
      end

      expect(subject.execute).to be_success
    end
  end

  it 'caches request' do
    expect(SecureRandom).to receive(:uuid).once.and_return('uuid')
    expect_next_instance_of(::Gitlab::Llm::Cache) do |cache|
      expect(cache).to receive(:add).with({ request_id: 'uuid', role: 'user' })
    end

    subject.execute
  end
end
