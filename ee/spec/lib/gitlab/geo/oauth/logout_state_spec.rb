# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Geo::Oauth::LogoutState, feature_category: :geo_replication do
  let(:salt) { 'MTAwZDhjYmQxNzUw' }
  let(:tag) { 'Y0D_b1xDW3uO-qN86c83HQ==' }
  let(:return_to) { 'http://fake-secondary.com:3000/project/test' }
  let(:access_token) { '48622af3df5b5b3e09b9754f2a3e5f3f10a94b4147d155b1029d827c112524d1' }
  let(:encrypted_token) { 't5fPL8_1KcFC5L945n9fcMRr7N-1J60LrOREQ9BAdur_K97tU1IpmWrN5-9P9aqpFvdL3SxzvP_z6CfO92BPsA==' }

  before do
    allow(Settings).to receive(:attr_encrypted_db_key_base_truncated)
      .and_return('4587f5984bf8f807ee320ed7b783e0c5')
  end

  describe '#encode' do
    it 'returns nil when token is nil' do
      subject = described_class.new(token: nil, return_to: return_to)

      expect(subject.encode).to be_nil
    end

    it 'returns nil when encryption fails' do
      allow_next_instance_of(OpenSSL::Cipher) do |instance|
        allow(instance).to receive(:final) { raise OpenSSL::OpenSSLError }
      end

      subject = described_class.new(token: access_token, return_to: return_to)

      expect(subject.encode).to be_nil
    end

    it 'returns a string with salt, tag, encrypted access token, and return_to full path colon separated' do
      subject = described_class.new(salt: salt, token: access_token, return_to: return_to)

      expect(subject.encode).to eq("#{salt}:#{tag}:#{encrypted_token}:/project/test")
    end

    it 'includes a empty value for return_to into state when return_to is nil' do
      subject = described_class.new(token: access_token, return_to: nil)

      state = subject.encode

      expect(state.split(':', 4)[3]).to eq ''
    end
  end

  describe '#decode' do
    it 'returns nil when salt is nil' do
      subject = described_class.new(salt: nil, token: encrypted_token, return_to: return_to)

      expect(subject.decode).to be_nil
    end

    it 'returns nil when salt has invalid base64' do
      subject = described_class.new(salt: 'invalid', tag: tag, token: encrypted_token, return_to: return_to)

      expect(subject.decode).to be_nil
    end

    it 'returns nil when tag is nil' do
      subject = described_class.new(salt: salt, tag: nil, token: encrypted_token, return_to: return_to)

      expect(subject.decode).to be_nil
    end

    it 'returns nil when encrypted token has invalid base64' do
      subject = described_class.new(salt: salt, tag: tag, token: 'invalid', return_to: return_to)

      expect(subject.decode).to be_nil
    end

    it 'returns nil when encrypted token is nil' do
      subject = described_class.new(salt: salt, tag: tag, token: nil, return_to: return_to)

      expect(subject.decode).to be_nil
    end

    it 'returns nil when decryption fails' do
      allow_next_instance_of(OpenSSL::Cipher) do |instance|
        allow(instance).to receive(:final) { raise OpenSSL::OpenSSLError }
      end

      subject = described_class.new(salt: salt, tag: tag, token: encrypted_token, return_to: return_to)

      expect(subject.decode).to be_nil
    end

    it 'returns nil when tag has an invalid byte size' do
      subject = described_class.new(salt: salt, tag: 'aW52YWxpZA==', token: encrypted_token, return_to: return_to)

      expect(subject.decode).to be_nil
    end

    it 'returns nil when tag has been modified' do
      subject = described_class.new(salt: salt, tag: 'MGY4MzY5YmU0OTk0', token: encrypted_token, return_to: return_to)

      expect(subject.decode).to be_nil
    end

    it 'returns nil when return_to has been modified' do
      subject = described_class.new(salt: salt, tag: tag, token: encrypted_token, return_to: '/foo/bar')

      expect(subject.decode).to be_nil
    end

    it 'returns access_token when token is recoverable' do
      subject = described_class.new(salt: salt, tag: tag, token: encrypted_token, return_to: return_to)

      expect(subject.decode).to eq(access_token)
    end
  end

  describe '#return_to' do
    it 'returns nil when return_to is nil' do
      subject = described_class.new(salt: salt, token: access_token, return_to: nil)

      expect(subject.return_to).to be_nil
    end

    it 'returns an empty string when return_to is empty' do
      subject = described_class.new(salt: salt, token: access_token, return_to: '')

      expect(subject.return_to).to eq('')
    end

    it 'returns the full path of the return_to URL' do
      subject = described_class.new(salt: salt, token: access_token, return_to: return_to)

      expect(subject.return_to).to eq('/project/test')
    end
  end
end
