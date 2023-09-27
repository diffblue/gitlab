# frozen_string_literal: true

RSpec.shared_examples 'code suggestion prompt' do
  describe '#request_params' do
    it 'returns expected request params' do
      expect(subject.request_params).to eq(request_params)
    end
  end
end
