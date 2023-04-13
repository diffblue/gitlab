# frozen_string_literal: true

require 'spec_helper'
require 'benchmark/ips'

RSpec.describe Gitlab::Ci::Reports::DependencyList::Report, feature_category: :software_composition_analysis do
  let(:report) { described_class.new }

  describe '#dependencies' do
    subject(:dependencies) { report.dependencies }

    context 'without dependency path information' do
      let(:dependency) { build :dependency }

      before do
        report.add_dependency(dependency)
      end

      it 'returns array of hashes' do
        expect(dependencies).to be_an(Array)
        expect(dependencies.first).to be_a(Hash)
      end

      it 'does not contain dependency path' do
        expect(dependencies.first[:location][:ancestors]).to be_nil
      end
    end

    context 'with dependency path information' do
      let(:indirect) { build :dependency, :with_vulnerabilities, iid: 32 }
      let(:direct) { build :dependency, :direct, :with_vulnerabilities }

      before do
        indirect[:location][:top_level] = false
        indirect[:location][:ancestors] = [{ iid: direct[:iid] }]

        report.add_dependency(direct)
        report.add_dependency(indirect)
      end

      it 'generates the dependency path' do
        ancestors = dependencies.second[:location][:ancestors]

        expect(ancestors.last).to eq({ name: direct[:name], version: direct[:version] })
      end

      context 'when dependency path info is not full' do
        let(:orphan_dependency) { build :dependency, :with_vulnerabilities, iid: 3 }

        before do
          report.add_dependency(orphan_dependency)
        end

        it 'returns array of hashes' do
          expect(dependencies).to be_an(Array)
          expect(dependencies.first).to be_a(Hash)
        end
      end

      context 'with multiple dependency files matching same package manager' do
        let(:indirect_other) { build :dependency, :with_vulnerabilities, iid: 32 }
        let(:direct_other) { build :dependency, :direct, :with_vulnerabilities }

        before do
          indirect_other[:location][:top_level] = false
          indirect_other[:location][:ancestors] = [{ iid: direct[:iid] }]
          indirect_other[:location][:path] = 'other_path.lock'
          direct_other[:location][:path] = 'other_path.lock'

          report.add_dependency(direct_other)
          report.add_dependency(indirect_other)
        end

        it 'generates the dependency path' do
          ancestors = dependencies.second[:location][:ancestors]
          ancestors_other = dependencies.last[:location][:ancestors]

          expect(ancestors.last).to eq({ name: direct[:name], version: direct[:version] })
          expect(ancestors_other.last).to eq({ name: direct_other[:name], version: direct_other[:version] })
        end
      end

      context 'when method is called more than once' do
        it 'generates path only once' do
          dependency_before = report.dependencies.last

          expect(dependency_before[:name]).to eq(indirect[:name])
          expect(dependency_before[:location][:ancestors].size).to eq(1)
          expect(dependency_before[:location][:ancestors].last[:name]).to eq(direct[:name])

          dependency_after = report.dependencies.last

          expect(dependency_after[:name]).to eq(indirect[:name])
          expect(dependency_after[:location][:ancestors].size).to eq(1)
          expect(dependency_after[:location][:ancestors].last[:name]).to eq(direct[:name])
        end
      end

      context 'with not vulnerable dependencies' do
        let(:indirect_secure) { build :dependency, iid: 13 }

        before do
          indirect_secure[:location][:top_level] = false
          indirect_secure[:location][:ancestors] = [{ iid: direct[:iid] }]

          report.add_dependency(indirect_secure)
        end

        it 'augment dependency path only for vulnerable dependencies' do
          vulnerable = dependencies.find { |dep| dep[:name] == indirect[:name] }
          secure = dependencies.find { |dep| dep[:name] == indirect_secure[:name] }

          expect(vulnerable[:location][:ancestors].last[:name]).to eq(direct[:name])
          expect(secure[:location][:ancestors]).to be_nil
        end
      end
    end
  end

  describe '#add_dependency' do
    let(:dependency) { build :dependency }

    it 'stores given dependency params in the map' do
      report.add_dependency(dependency)

      expect(report.dependencies).to eq([dependency])
    end

    it 'does not duplicate same dependency' do
      report.add_dependency(dependency)
      report.add_dependency(dependency.dup)

      expect(report.dependencies.first).to eq(dependency)
    end

    it 'does not duplicate same vulnerability for dependency' do
      vulnerabilities = [{ name: 'problem', severity: 'high', id: 2, url: 'some_url_2' },
                         { name: 'problem2', severity: 'medium', id: 4, url: 'some_url_4' },
                         { name: 'problem3', severity: 'medium', id: nil, url: nil }]

      dependency[:vulnerabilities] = [vulnerabilities.first]
      with_extra_vuln_from_another_report = dependency.dup.merge(vulnerabilities: vulnerabilities)

      report.add_dependency(dependency)
      report.add_dependency(with_extra_vuln_from_another_report)
      expect(report.dependencies.first.dig(:vulnerabilities)).to eq(vulnerabilities)
    end

    it 'stores a dependency' do
      dependency[:packager] = 'Ruby (Bundler)'
      dependency[:vulnerabilities] = [{ name: 'abc', severity: 'high', id: 5, url: 'some_url_5' }]

      report.add_dependency(dependency)
      expect(report.dependencies.size).to eq(1)
      expect(report.dependencies.first[:packager]).to eq('Ruby (Bundler)')
      expect(report.dependencies.first[:vulnerabilities]).to eq([{ name: 'abc', severity: 'high', id: 5, url: 'some_url_5' }])
    end
  end

  describe '#apply_license' do
    subject { report.dependencies.last[:licenses].size }

    let(:license) { build(:ci_reports_license_scanning_report, :mit).licenses.first }

    let(:purl_type_of_dependency_with_license) { dependency[:purl_type] }

    before do
      license.add_dependency(name: name_of_dependency_with_license, purl_type: purl_type_of_dependency_with_license)
      report.add_dependency(dependency)
      report.apply_license(license)
    end

    context 'with matching dependency' do
      let(:name_of_dependency_with_license) { dependency[:name] }

      context 'with empty license list' do
        let(:dependency) { build :dependency }

        it 'applies license' do
          is_expected.to eq(1)
        end
      end

      context 'with dependency with non-canonical representation' do
        let(:dependency) { build :dependency, name: 'Irigokon', purl_type: 'pypi' }
        let(:name_of_dependency_with_license) { dependency[:name].downcase }

        it 'applies license' do
          is_expected.to eq(1)
        end
      end

      context 'with full license list' do
        let(:dependency) { build :dependency, :with_licenses }

        it 'does not apply the license a second time' do
          is_expected.to eq(1)
        end
      end
    end

    context 'without matching dependency' do
      let(:dependency) { build :dependency, name: 'irigokon' }
      let(:name_of_dependency_with_license) { dependency[:name].reverse }

      it 'does not apply the license at all' do
        is_expected.to eq(0)
      end
    end
  end

  describe '#dependencies_with_licenses' do
    subject { report.dependencies_with_licenses }

    context 'with found dependencies' do
      let(:plain_dependency) { build :dependency }

      before do
        report.add_dependency(plain_dependency)
      end

      context 'with existing license' do
        let(:dependency) { build :dependency, :with_licenses }

        before do
          report.add_dependency(dependency)
        end

        it 'returns only dependency with license' do
          expect(subject.size).to eq(1)
          expect(subject.first).to eq(dependency)
        end
      end

      context 'without existing license' do
        it 'returns empty array' do
          expect(subject).to be_empty
        end
      end
    end

    context 'without found dependencies' do
      it 'returns empty array' do
        expect(subject).to be_empty
      end
    end
  end
end
