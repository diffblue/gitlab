# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Geo::Oauth::LoginState, feature_category: :geo_replication do
  let(:salt) { 'b9653b6aa2ff6b54' }
  let(:token) { 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJkYXRhIjp7InJldHVybl90byI6Ii9wcm9qZWN0L3Rlc3Q_Zm9vPWJhciN6b28ifSwianRpIjoiODdjZDQ2M2MtOTgyNC00ZjliLWI5NDMtOGFkMjJmY2E2MmZhIiwiaWF0IjoxNTQ5ODI1MjAwLCJuYmYiOjE1NDk4MjUxOTUsImV4cCI6MTU0OTgyNTI2MH0.qZE6kuoeW6BK1URuIl8l8MiCfGjtTTXixVdMCE80gVA' }
  let(:return_to) { 'http://fake-secondary.com:3000/project/test?foo=bar#zoo' }
  let(:timestamp) { Time.utc(2019, 2, 10, 19, 0, 0) }

  around do |example|
    if example.metadata[:no_traveling]
      example.run
    else
      travel_to(timestamp) { example.run }
    end
  end

  before do
    allow(Gitlab::Application.secrets).to receive(:secret_key_base)
      .and_return('712f2a504647cb8aa7b06f2273c1db026dd9d2566acf228cd44f25f7d372c165af72209f34cb9df6623780425ce717884cf0c7f85c1deb108bd45a8cd2c93427')
  end

  describe '.from_state' do
    it 'returns a invalid instance when state is nil' do
      expect(described_class.from_state(nil)).not_to be_valid
    end

    it 'returns a invalid instance when state is empty' do
      expect(described_class.from_state('')).not_to be_valid
    end

    it 'returns a valid instance when state is valid' do
      expect(described_class.from_state("#{salt}:#{token}:#{return_to}")).to be_valid
    end
  end

  describe '#valid?' do
    it 'returns false when return_to is nil' do
      subject = described_class.new(return_to: nil)

      expect(subject.valid?).to eq false
    end

    it 'returns false when return_to is empty' do
      subject = described_class.new(return_to: '')

      expect(subject.valid?).to eq false
    end

    it 'returns false when token is nil' do
      subject = described_class.new(return_to: return_to, salt: salt, token: nil)

      expect(subject.valid?).to eq false
    end

    it 'returns false when token is empty' do
      subject = described_class.new(return_to: return_to, salt: salt, token: '')

      expect(subject.valid?).to eq false
    end

    it 'returns false when salt not match' do
      subject = described_class.new(return_to: return_to, salt: 'invalid-salt', token: token)

      expect(subject.valid?).to eq(false)
    end

    it 'returns false when token does not match' do
      subject = described_class.new(return_to: return_to, salt: salt, token: 'invalid-token')

      expect(subject.valid?).to eq(false)
    end

    it "returns false when token's expired", :no_traveling do
      subject = travel_to(timestamp) do
        described_class.new(return_to: return_to, salt: salt, token: token)
      end

      # Needs to be at least 120 seconds, because the default expiry is
      # 60 seconds with an additional 60 second leeway.
      travel_to(timestamp + 125) do
        expect(subject.valid?).to eq(false)
      end
    end

    it 'returns true when token matches' do
      subject = described_class.new(return_to: return_to, salt: salt, token: token)

      expect(subject.valid?).to eq(true)
    end
  end

  describe '#encode' do
    it 'does not raise an error when return_to is nil' do
      subject = described_class.new(return_to: nil)

      expect { subject.encode }.not_to raise_error
    end

    it 'returns a string with salt, token, and return_to colon separated' do
      subject = described_class.new(return_to: return_to)

      salt, token, return_to = subject.encode.split(':', 3)

      expect(salt).not_to be_blank
      expect(token).not_to be_blank
      expect(return_to).to eq return_to
    end
  end

  describe '#return_to' do
    it 'returns nil when return_to is nil' do
      subject = described_class.new(return_to: nil)

      expect(subject.return_to).to be_nil
    end

    it 'returns an empty string when return_to is empty' do
      subject = described_class.new(return_to: '')

      expect(subject.return_to).to eq('')
    end

    it 'returns the full path of the return_to URL' do
      subject = described_class.new(return_to: return_to)

      expect(subject.return_to).to eq('/project/test?foo=bar#zoo')
    end
  end
end
