# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Reports::Security::Locations::ClusterImageScanning do
  context 'when cluster_id is provided in finding' do
    let(:params) do
      {
        image: 'registry.gitlab.com/my/project:latest',
        cluster_id: '1',
        operating_system: 'debian:9',
        package_name: 'glibc',
        package_version: '1.2.3'
      }
    end

    let(:mandatory_params) { %i[image operating_system] }
    let(:expected_fingerprint) { Digest::SHA1.hexdigest('registry.gitlab.com/my/project:glibc') }
    let(:expected_fingerprint_path) { 'registry.gitlab.com/my/project:glibc' }

    it_behaves_like 'vulnerability location'
  end

  context 'when agent id is provided in finding' do
    let(:params) do
      {
        image: 'registry.gitlab.com/my/project:latest',
        agent_id: '46357',
        operating_system: 'debian:9',
        package_name: 'glibc',
        package_version: '1.2.3'
      }
    end

    let(:mandatory_params) { %i[image operating_system] }
    let(:expected_fingerprint) { Digest::SHA1.hexdigest('AGENT_46357:registry.gitlab.com/my/project:glibc') }
    let(:expected_fingerprint_path) { 'AGENT_46357:registry.gitlab.com/my/project:glibc' }

    it_behaves_like 'vulnerability location'
  end
end
