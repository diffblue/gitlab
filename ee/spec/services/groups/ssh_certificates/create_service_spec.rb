# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::SshCertificates::CreateService, '#execute', feature_category: :groups_and_projects do
  let_it_be(:group, reload: true) { create(:group) }
  let(:title) { 'Title 1' }
  let(:key) { generate_key }
  let(:ssh_certificate_params) { { title: title, key: key } }
  let(:service) { described_class.new(group, ssh_certificate_params) }

  context 'when group and params are provided' do
    it 'succeeds' do
      expect(group.ssh_certificates.size).to eq(0)
      service.execute
      expect(group.ssh_certificates.size).to eq(1)
      expect(group.ssh_certificates.first.title).to eq(title)
      expect(group.ssh_certificates.first.key).to eq(key)
    end
  end

  context 'when title is blank' do
    let(:title) { '' }

    it 'fails with validation error' do
      response = service.execute
      expect(response.success?).to eq(false)
      expect(response.errors.first).to eq("Validation failed: Title can't be blank")
    end
  end

  context 'when key is blank' do
    let(:key) { '' }

    it 'fails with validation error' do
      response = service.execute
      expect(response.success?).to eq(false)
      expect(response.errors.first).to eq("Validation failed: Invalid key")
    end
  end

  context 'when key is incorrectly formatted' do
    let(:key) { 'ssh-rsa AAAB3NzaC1yc2EAAAADAQABAAAAgQCxT+' }

    it 'fails with validation error' do
      response = service.execute
      expect(response.success?).to eq(false)
      expect(response.errors.first).to eq("Validation failed: Invalid key")
    end
  end

  def generate_key
    SSHData::PrivateKey::RSA.generate(
      ::Gitlab::SSHPublicKey.supported_sizes(:rsa).min, unsafe_allow_small_key: true
    ).public_key.openssh(comment: 'example@gitlab.com')
  end
end
