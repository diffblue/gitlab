# frozen_string_literal: true

RSpec.shared_examples 'measured Llm request' do
  it 'inrements llm_client_request counter' do
    expect(Gitlab::Metrics::Sli::Apdex[:llm_client_request])
      .to receive(:increment).with(labels: { client: client }, success: true)

    subject
  end
end

RSpec.shared_examples 'measured Llm request with error' do
  it 'inrements llm_client_request counter with success false' do
    expect(Gitlab::Metrics::Sli::Apdex[:llm_client_request])
      .to receive(:increment).with(labels: { client: client }, success: false)

    expect { subject }.to raise_error(StandardError)
  end
end
