# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Parsers::Security::Formatters::DependencyList do
  let(:formatter) { described_class.new(project, sha) }
  let(:project) { create(:project) }
  let(:sha) { '4242424242424242' }

  let(:parsed_report) do
    Gitlab::Json.parse!(
      File.read(
        Rails.root.join('ee/spec/fixtures/security_reports/dependency_list/gl-dependency-scanning-report.json')
      )
    )
  end

  describe '#format' do
    let(:package_manager) { 'bundler' }
    let(:file_path) { 'file.path' }
    let(:data) { formatter.format(dependency, package_manager, file_path) }
    let(:blob_path) { "/#{project.full_path}/-/blob/#{sha}/file.path" }

    context 'with secure dependency' do
      context 'with top-level dependency' do
        let(:dependency) { parsed_report['dependency_files'][1]['dependencies'][0] }

        it 'formats the dependency' do
          expect(data[:name]).to eq('async')
          expect(data[:iid]).to eq(1)
          expect(data[:location][:blob_path]).to eq(blob_path)
          expect(data[:location][:path]).to eq('file.path')
          expect(data[:location][:top_level]).to be_truthy
          expect(data[:location][:ancestors]).to be_nil
        end
      end

      context 'with dependency path included' do
        let(:dependency) { parsed_report['dependency_files'][1]['dependencies'][4] }

        it 'formats the dependency' do
          expect(data[:name]).to eq('ms')
          expect(data[:iid]).to eq(5)
          expect(data[:location][:blob_path]).to eq(blob_path)
          expect(data[:location][:path]).to eq('file.path')
          expect(data[:location][:top_level]).to be_falsey
          expect(data[:location][:ancestors][0][:iid]).to eq(3)
        end
      end

      context 'without dependency path' do
        let(:dependency) { parsed_report['dependency_files'][0]['dependencies'][0] }

        it 'formats the dependency' do
          expect(data[:name]).to eq('mini_portile2')
          expect(data[:iid]).to be_nil
          expect(data[:packager]).to eq('Ruby (Bundler)')
          expect(data[:package_manager]).to eq('bundler')
          expect(data[:location][:blob_path]).to eq(blob_path)
          expect(data[:location][:path]).to eq('file.path')
          expect(data[:location][:top_level]).to be_nil
          expect(data[:location][:ancestors]).to be_nil
          expect(data[:version]).to eq('2.2.0')
          expect(data[:vulnerabilities]).to be_empty
          expect(data[:licenses]).to be_empty
        end
      end
    end

    context 'with vulnerable dependency' do
      let(:dependency) { parsed_report['dependency_files'][0]['dependencies'][1] }
      let(:data) { formatter.format(dependency, package_manager, file_path, vulnerability_data) }
      let_it_be(:standalone_vulnerability) { create(:vulnerability, report_type: :dependency_scanning) }

      let(:vulnerability_data) do
        create(:vulnerabilities_finding, :with_dependency_scanning_metadata, vulnerability: standalone_vulnerability)
      end

      it 'merge vulnerabilities data' do
        vulnerability = data[:vulnerabilities].first
        path = "/security/vulnerabilities/#{standalone_vulnerability.id}"

        expect(vulnerability[:id]).to eq(standalone_vulnerability.id)
        expect(vulnerability[:url]).to end_with(path)
        expect(vulnerability[:name]).to eq('Vulnerabilities in libxml2')
        expect(vulnerability[:severity]).to eq('high')
      end
    end
  end

  describe 'packager' do
    using RSpec::Parameterized::TableSyntax

    where(:packager, :expected) do
      'bundler'    | 'Ruby (Bundler)'
      'yarn'       | 'JavaScript (Yarn)'
      'npm'        | 'JavaScript (npm)'
      'pip'        | 'Python (pip)'
      'maven'      | 'Java (Maven)'
      'composer'   | 'PHP (Composer)'
      'conan'      | 'C/C++ (Conan)'
      'sbt'        | 'Scala (Sbt)'
      'nuget'      | 'C# (Nuget)'
      'go'         | 'Go (Go modules)'
      'gradle'     | 'Java (Gradle)'
      'pipenv'     | 'Python (Pipenv)'
      'setuptools' | 'Python (Setuptools)'
      ''           | ''
    end

    with_them do
      it 'substitutes with right values' do
        expect(formatter.send(:packager, packager)).to eq(expected)
      end
    end
  end
end
