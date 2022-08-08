# frozen_string_literal: true

RSpec.shared_examples 'support for elasticsearch timeouts' do |action, params, method_to_stub, format|
  before do
    allow_next_instance_of(SearchService) do |service|
      allow(service).to receive(method_to_stub).and_raise(Elastic::TimeoutError)
    end
  end

  it 'renders a 408 when a timeout occurs' do
    get action, params: params, format: format

    expect(response).to have_gitlab_http_status(:request_timeout)
  end
end
