# frozen_string_literal: true

RSpec.shared_examples 'async Llm service' do
  it 'executes the service asynchronously' do
    expected_options = options.merge(request_id: 'uuid')

    expect(SecureRandom).to receive(:uuid).twice.and_return('uuid')
    expect(::Llm::CompletionWorker)
      .to receive(:perform_async)
      .with(user.id, resource.id, resource.class.name, action_name, expected_options)

    expect(subject.execute).to be_success
  end

  it 'caches request' do
    expect(SecureRandom).to receive(:uuid).once.and_return('uuid')
    expect_next_instance_of(::Gitlab::Llm::Cache) do |cache|
      expect(cache).to receive(:add).with({ request_id: 'uuid', role: 'user' })
    end

    subject.execute
  end
end
