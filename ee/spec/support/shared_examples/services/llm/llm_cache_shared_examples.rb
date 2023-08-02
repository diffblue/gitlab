# frozen_string_literal: true

RSpec.shared_examples 'llm service caches user request' do
  let(:expected_cache_payload) do
    {
      request_id: 'uuid',
      role: 'user',
      timestamp: an_instance_of(ActiveSupport::TimeWithZone),
      content: content
    }
  end

  before do
    allow(SecureRandom).to receive(:uuid).and_return('uuid')
  end

  it 'caches response' do
    expect_next_instance_of(::Gitlab::Llm::Cache) do |cache|
      expect(cache).to receive(:add).with(expected_cache_payload)
    end

    subject.execute
  end

  context 'when a special reset message is used' do
    let(:content) { '/reset' }

    before do
      allow(subject).to receive(:content).and_return(content)
    end

    it 'only stores the message in cache' do
      expect(::Llm::CompletionWorker).not_to receive(:perform_async)

      expect_next_instance_of(::Gitlab::Llm::Cache) do |cache|
        expect(cache).to receive(:add).with(expected_cache_payload)
      end

      subject.execute
    end
  end
end

RSpec.shared_examples 'llm service does not cache user request' do
  it 'does not cache the request' do
    expect(::Gitlab::Llm::Cache).not_to receive(:new)

    subject.execute
  end
end
