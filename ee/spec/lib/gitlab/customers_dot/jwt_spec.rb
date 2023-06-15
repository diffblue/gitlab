# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::CustomersDot::Jwt do
  let_it_be(:user) { create(:user) }

  subject(:customers_dot_jwt) { described_class.new(user) }

  describe '#payload' do
    subject(:payload) { customers_dot_jwt.payload }

    it 'has correct values for JWT attributes', :freeze_time, :aggregate_failures do
      now = Time.now.to_i

      expect(payload[:iss]).to eq(Settings.gitlab.host)
      expect(payload[:iat]).to eq(now)
      expect(payload[:exp]).to eq(now + Gitlab::CustomersDot::Jwt::DEFAULT_EXPIRE_TIME)
      expect(payload[:sub]).to eq("gitlab_user_id_#{user.id}")
    end
  end

  describe '#encoded' do
    let(:key) { OpenSSL::PKey::RSA.new(2048) }

    before do
      allow(Gitlab::CurrentSettings).to receive(:customers_dot_jwt_signing_key).and_return(key)
    end

    subject(:encoded) { customers_dot_jwt.encoded }

    it 'generates encoded token' do
      expect(encoded).to be_a String
    end

    context 'with no signing key' do
      let(:key) { nil }

      it 'raises error' do
        expect { encoded }.to raise_error(Gitlab::CustomersDot::Jwt::NoSigningKeyError)
      end
    end
  end
end
