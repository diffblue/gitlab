# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::SshCertificates::DestroyService, '#execute', feature_category: :groups_and_projects do
  let_it_be(:ssh_certificate) { create(:group_ssh_certificate) }
  let_it_be(:group, reload: true) { create(:group, ssh_certificates: [ssh_certificate]) }

  let(:ssh_certificate_params) { { ssh_certificates_id: ssh_certificate.id } }
  let(:service) { described_class.new(group, ssh_certificate_params) }

  context 'when group and params are provided' do
    it 'succeeds' do
      expect(group.ssh_certificates.size).to eq(1)
      service.execute
      expect(group.ssh_certificates.size).to eq(0)
    end
  end

  context 'when ssh_certificate_id is not provided' do
    let(:ssh_certificate_params) { {} }

    it 'fails with validation error' do
      response = service.execute
      expect(response.success?).to eq(false)
      expect(response.errors.first).to eq("SSH Certificate not found")
    end
  end

  context "when ssh_certificate doesn't exist" do
    let(:ssh_certificate_params) { { ssh_certificates_id: 9999 } }

    it 'fails with validation error' do
      response = service.execute
      expect(response.success?).to eq(false)
      expect(response.errors.first).to eq("SSH Certificate not found")
    end
  end
end
