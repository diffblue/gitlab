# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Reports::DependencyList::Dependency do
  let(:dependency_nokogiri) do
    {
      name: 'nokogiri',
      version: '1.8.0',
      packager: 'Ruby (Bundler)',
      package_manager: 'Ruby (Bundler)',
      location: {
        blob_path: '/some_project/path/package_file.lock',
        path: 'package_file.lock',
        ancestors: nil,
        top_level: true
      },
      licenses: [],
      vulnerabilities: [ddos_vuln, xss_vuln]
    }
  end

  let(:ddos_vuln) { { name: 'DDoS', severity: 'high', id: 12, url: 'some_url_12' } }
  let(:xss_vuln) { { name: 'XSS vulnerability', severity: 'low', id: 4, url: 'some_url_4' } }
  let(:problem_vuln) { { name: 'problem', severity: 'high', id: 3, url: 'some_url_3' } }

  context 'initialize' do
    it 'sets all required properties' do
      dep = described_class.new(dependency_nokogiri)

      expect(dep.to_hash).to eq({ name: 'nokogiri',
                                  packager: 'Ruby (Bundler)',
                                  package_manager: 'Ruby (Bundler)',
                                  location: { blob_path: '/some_project/path/package_file.lock', path: 'package_file.lock', top_level: true, ancestors: nil },
                                  version: '1.8.0',
                                  licenses: [],
                                  vulnerabilities: [ddos_vuln, xss_vuln] })
    end

    it 'keeps vulnerabilities that are not duplicates' do
      dependency_nokogiri[:vulnerabilities] << problem_vuln
      dep = described_class.new(dependency_nokogiri)

      expect(dep.vulnerabilities.to_a.map(&:to_hash)).to eq([ddos_vuln, xss_vuln, problem_vuln])
    end

    it 'removes vulnerability duplicates' do
      dependency_nokogiri[:vulnerabilities] << ddos_vuln
      dep = described_class.new(dependency_nokogiri)

      expect(dep.vulnerabilities.to_a.map(&:to_hash)).to eq([ddos_vuln, xss_vuln])
    end
  end

  context 'update dependency' do
    specify do
      dependency_nokogiri[:vulnerabilities] << ddos_vuln << problem_vuln
      dep = described_class.new(dependency_nokogiri)

      expect(dep.vulnerabilities.to_a.map(&:to_hash)).to eq([ddos_vuln, xss_vuln, problem_vuln])
    end
  end
end
