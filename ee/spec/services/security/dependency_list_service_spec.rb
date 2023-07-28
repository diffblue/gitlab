# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::DependencyListService, feature_category: :vulnerability_management do
  describe '#execute' do
    let_it_be(:pipeline) { create(:ee_ci_pipeline, :with_dependency_list_report) }
    let_it_be(:nokogiri_finding) { create(:vulnerabilities_finding, :detected, :with_dependency_scanning_metadata, :with_pipeline, raw_severity: 'High') }
    let_it_be(:nokogiri_pipeline) { create(:vulnerabilities_finding_pipeline, finding: nokogiri_finding, pipeline: pipeline) }

    let_it_be(:unknown_severity_finding) { create(:vulnerabilities_finding, :detected, :with_dependency_scanning_metadata, package: 'saml2-js', file: 'yarn/yarn.lock', version: '1.5.0', raw_severity: 'Unknown') }
    let_it_be(:medium_severity_finding) { create(:vulnerabilities_finding, :detected, :with_dependency_scanning_metadata, package: 'saml2-js', file: 'yarn/yarn.lock',  version: '1.5.0', raw_severity: 'Medium') }
    let_it_be(:critical_severity_finding) { create(:vulnerabilities_finding, :detected, :with_dependency_scanning_metadata, package: 'saml2-js', file: 'yarn/yarn.lock', version: '1.5.0', raw_severity: 'Critical') }

    let_it_be(:unknown_severity_pipeline) { create(:vulnerabilities_finding_pipeline, finding: unknown_severity_finding, pipeline: pipeline) }
    let_it_be(:medium_severity_pipeline) { create(:vulnerabilities_finding_pipeline, finding: medium_severity_finding, pipeline: pipeline) }
    let_it_be(:critical_severity_pipeline) { create(:vulnerabilities_finding_pipeline, finding: critical_severity_finding, pipeline: pipeline) }

    subject { described_class.new(pipeline: pipeline, params: params).execute }

    before do
      stub_licensed_features(dependency_scanning: true)
    end

    context 'without params' do
      let(:params) { {} }

      it 'returns array of dependencies' do
        is_expected.to be_an(Array)
      end

      it 'is sorted by names by default' do
        expect(subject.total_count).to eq(21)
        expect(subject.first[:name]).to eq('async')
        expect(subject.per(subject.total_count).last[:name]).to eq('xpath.js')
      end
    end

    context 'with params' do
      context 'filtered by package_managers' do
        before do
          dependencies = described_class::FILTER_PACKAGE_MANAGERS_VALUES.map do |package_manager|
            build(:dependency, package_manager: package_manager)
          end

          allow(pipeline).to receive_message_chain(:dependency_list_report, :dependencies).and_return(dependencies)
        end

        context 'with matching package manager' do
          where(package_manager: described_class::FILTER_PACKAGE_MANAGERS_VALUES)

          with_them do
            let(:params) { { package_manager: package_manager } }

            it 'returns filtered items' do
              expect(subject.size).to eq(1)
              expect(subject.first[:package_manager]).to eq(package_manager)
            end
          end
        end

        context 'with all package managers' do
          let(:params) { { package_manager: described_class::FILTER_PACKAGE_MANAGERS_VALUES } }

          it 'returns all items' do
            expect(subject.size).to eq(described_class::FILTER_PACKAGE_MANAGERS_VALUES.size)
          end
        end

        context 'with invalid package manager' do
          let(:params) { { package_manager: 'package_manager' } }

          it 'returns nothing' do
            expect(subject.size).to eq(0)
          end
        end
      end

      context 'filtered by vulnerable' do
        let(:params) { { filter: 'vulnerable' } }

        it 'returns filtered items' do
          expect(subject.size).to eq(2)
          expect(subject.last[:vulnerabilities]).not_to be_empty
        end
      end

      context 'sorted desc by packagers' do
        let(:params) do
          {
            sort: 'desc',
            sort_by: 'packager'
          }
        end

        it 'returns array of data properly sorted' do
          expect(subject.first[:packager]).to eq('Ruby (Bundler)')
          expect(subject.last[:packager]).to eq('JavaScript (Yarn)')
        end
      end

      context 'sorted asc by packagers' do
        let(:params) do
          {
            sort: 'asc',
            sort_by: 'packager'
          }
        end

        it 'returns array of data properly sorted' do
          expect(subject.first[:packager]).to eq('JavaScript (Yarn)')
          expect(subject.last[:packager]).to eq('Ruby (Bundler)')
        end
      end

      context 'sorted desc by names' do
        let(:params) do
          {
            sort: 'desc',
            sort_by: 'name'
          }
        end

        it 'returns array of data properly sorted' do
          expect(subject.first[:name]).to eq('xpath.js')
          expect(subject.last[:name]).to eq('async')
        end
      end

      context 'sorted by severity' do
        let(:params) do
          {
            sort_by: 'severity'
          }
        end

        context 'in descending order' do
          before do
            params[:sort] = 'desc'
          end

          it 'returns array of data sorted by package severity level in descending order' do
            dependencies = subject.first(2).map do |dependency|
              {
                name: dependency[:name],
                vulnerabilities: dependency[:vulnerabilities].pluck(:severity)
              }
            end

            expect(dependencies).to eq([{ name: "saml2-js", vulnerabilities: %w(critical medium unknown) },
                                        { name: "nokogiri", vulnerabilities: ["high"] }])
          end
        end

        context 'in ascending order' do
          before do
            params[:sort] = 'asc'
          end

          it 'returns array of data sorted by package severity level in ascending order' do
            dependencies = subject.per(subject.total_count).last(2).map do |dependency|
              {
                name: dependency[:name],
                vulnerabilities: dependency[:vulnerabilities].pluck(:severity)
              }
            end

            expect(dependencies).to eq([{ name: "nokogiri", vulnerabilities: ["high"] },
                                        { name: "saml2-js", vulnerabilities: %w(critical medium unknown) }])
          end
        end
      end

      context 'add licenses' do
        let_it_be(:pipeline) { create(:ee_ci_pipeline) }
        let(:params) { { page: '2', per_page: '3' } }

        context 'testing permutations of dependency_scanning and license_scanning licensed features' do
          using RSpec::Parameterized::TableSyntax

          where(:dependency_scanning_feature, :license_scanning_feature, :licenses_applied) do
            true  | true  | true
            true  | false | false
            false | true  | false
            false | false | false
          end

          let(:license_scanner) do
            instance_double(::Gitlab::LicenseScanning::SbomScanner, has_data?: true, add_licenses: true)
          end

          with_them do
            before do
              stub_licensed_features(dependency_scanning: dependency_scanning_feature,
                license_scanning: license_scanning_feature)
              allow(::Gitlab::LicenseScanning).to receive(:scanner_for_pipeline).and_return(license_scanner)
            end

            it "checks whether licenses should be applied" do
              if licenses_applied
                expect(license_scanner).to receive(:add_licenses)
              else
                expect(license_scanner).not_to receive(:add_licenses)
              end

              subject
            end
          end
        end

        context 'when license and dependency scanning features are available' do
          before do
            stub_licensed_features(dependency_scanning: true, license_scanning: true)
          end

          shared_examples 'paginate license application' do
            it 'returns the requested number of dependencies' do
              expect(subject.length).to eq(3)
            end

            it 'add licenses only to current page' do
              expect(subject.total_count).to eq(56)
              expect(::Gitlab::LicenseScanning.scanner_for_pipeline(pipeline.project, pipeline)).to be_a scanner_type

              expect(found_licenses_on_page(2)).to be_truthy
              expect(found_licenses_on_page(1)).to be_falsey
            end

            context 'when license scanner does not have data' do
              before do
                allow(pipeline).to receive(:has_reports?).and_return(false)
              end

              it 'does not add licenses' do
                expect(found_licenses_on_page(2)).to be_falsey
              end
            end
          end

          context 'when the pipeline has a build with a license scanning report' do
            let(:scanner_type) { ::Gitlab::LicenseScanning::ArtifactScanner }

            before do
              pipeline.builds << create(:ee_ci_build, :success, :dependency_scanning_with_matching_licenses, pipeline: pipeline)
            end

            it_behaves_like 'paginate license application'
          end

          context 'when the pipeline has a build with a cyclonedx sbom scanning report' do
            let(:scanner_type) { ::Gitlab::LicenseScanning::SbomScanner }

            before do
              pipeline.builds << create(:ee_ci_build, :success, :cyclonedx_with_matching_dependency_files, pipeline: pipeline)
            end

            it_behaves_like 'paginate license application'

            context 'with dependency with non-canonical representation' do
              let(:params) { { page: '1', per_page: '3' } }
              let(:capitalized_name) { 'Django' }
              let(:normalized_name) { 'django' }

              before do
                create(:pm_package, name: normalized_name, purl_type: "pypi",
                  other_licenses: [{ license_names: ["MIT"], versions: ["1.11.4"] }])
              end

              it 'matches the normalized name to add licenses' do
                expect(subject.pluck(:name)).to include(capitalized_name)
                expect(subject.pluck(:licenses)).to include(
                  [name: "MIT", url: "https://spdx.org/licenses/MIT.html"])
              end
            end
          end

          context 'when skip pagination is true' do
            subject(:dependency_list) do
              described_class.new(pipeline: pipeline, params: params).execute(skip_pagination: true)
            end

            before do
              pipeline.builds << create(:ee_ci_build, :success, :cyclonedx_with_matching_dependency_files, pipeline: pipeline)
            end

            it 'add licenses to all records' do
              expect(dependency_list.count).to be 56
              expect(dependency_list.pluck(:licenses).all?(&:any?)).to be_truthy
            end
          end
        end

        def found_licenses_on_page(number)
          subject.page(number).pluck(:licenses).all?(&:any?)
        end
      end
    end
  end
end
