# frozen_string_literal: true

RSpec.shared_examples 'measured Llm request' do
  it 'inrements llm_client_request counter' do
    expect(Gitlab::Metrics::Sli::ErrorRate[:llm_client_request])
      .to receive(:increment).with(labels: { client: client }, error: false)

    subject
  end
end

RSpec.shared_examples 'measured Llm request with error' do |error_cls|
  it 'inrements llm_client_request counter with success false' do
    expect(Gitlab::Metrics::Sli::ErrorRate[:llm_client_request])
      .to receive(:increment).with(labels: { client: client }, error: true)

    expect { subject }.to raise_error(error_cls)
  end
end
