# frozen_string_literal: true

RSpec.shared_examples 'a geo RequestService' do
  include ::EE::GeoHelpers
  include ApiHelpers

  let_it_be(:primary) { create(:geo_node, :primary) } unless method_defined?(:primary)

  describe '#execute' do
    it 'parses a 401 response' do
      response = double(
        success?: false,
        code: 401,
        message: 'Unauthorized',
        parsed_response: { 'message' => 'Test' }
      )
      allow(Gitlab::HTTP).to receive(:perform_request).and_return(response)
      expect(subject).to receive(:log_error).with("Could not connect to Geo primary node - HTTP Status Code: 401 Unauthorized\nTest")

      expect(subject.execute).to be_falsey
    end

    it 'alerts on bad SSL certficate' do
      allow(Gitlab::HTTP).to receive(:perform_request).and_raise(OpenSSL::SSL::SSLError.new('bad certificate'))
      expect(subject).to receive(:log_error).with(/Failed to Net::HTTP::(Put|Post) to primary url: /, kind_of(OpenSSL::SSL::SSLError))

      expect(subject.execute).to be_falsey
    end

    it 'handles connection refused' do
      allow(Gitlab::HTTP).to receive(:perform_request).and_raise(Errno::ECONNREFUSED.new('bad connection'))

      expect(subject).to receive(:log_error).with(/Failed to Net::HTTP::(Put|Post) to primary url: /, kind_of(Errno::ECONNREFUSED))

      expect(subject.execute).to be_falsey
    end

    it 'returns meaningful error message when primary uses incorrect db key' do
      allow(Gitlab::Geo).to receive(:primary_node).and_raise(OpenSSL::Cipher::CipherError)

      expect(subject).to receive(:log_error).with(
        "Error decrypting the Geo secret from the database. Check that the primary uses the correct db_key_base.",
        kind_of(OpenSSL::Cipher::CipherError)
      )

      expect(subject.execute).to be_falsey
    end

    it 'gracefully handles case when primary is deleted' do
      primary.destroy!

      expect(subject.execute).to be_falsey
    end
  end
end
