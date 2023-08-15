# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CompareLicenseScanningReportsService, feature_category: :software_composition_analysis do
  include ProjectForksHelper

  let_it_be(:project) { create(:project, :repository) }

  let(:service) { described_class.new(project, nil) }

  before do
    stub_licensed_features(license_scanning: true)
  end

  describe '#execute' do
    subject { service.execute(base_pipeline, head_pipeline) }

    context "when loading data for multiple reports" do
      it 'loads the data efficiently' do
        base_pipeline = create(:ee_ci_pipeline, project: project)
        head_pipeline = create(:ee_ci_pipeline, :with_cyclonedx_report, project: project)

        control_count = ActiveRecord::QueryRecorder.new do
          service.execute(base_pipeline.reload, head_pipeline.reload)
        end.count

        new_head_pipeline = create(:ee_ci_pipeline, :with_cyclonedx_report, project: project)

        expect do
          service.execute(base_pipeline.reload, new_head_pipeline.reload)
        end.not_to exceed_query_limit(control_count)
      end
    end

    context 'when head pipeline has test reports' do
      context 'with incorrect report type' do
        let!(:base_pipeline) { nil }
        let!(:head_pipeline) { create(:ee_ci_pipeline, :with_license_scanning_report, project: project) }

        it 'reports new licenses' do
          expect(subject[:status]).to eq(:parsed)
          expect(subject[:data]['new_licenses']).to be_empty
          expect(subject[:data]['existing_licenses']).to be_empty
          expect(subject[:data]['removed_licenses']).to be_empty
        end
      end

      context 'with cyclonedx report' do
        let!(:base_pipeline) { nil }
        let!(:head_pipeline) { create(:ee_ci_pipeline, :with_cyclonedx_report, project: project) }

        context 'when querying uncompressed package metadata' do
          before do
            stub_feature_flags(compressed_package_metadata_query: false)

            create(:pm_package_version_license, :with_all_relations, name: "nokogiri", purl_type: "gem", version: "1.8.0", license_name: "BSD")
          end

          it 'reports new licenses' do
            expect(subject[:status]).to eq(:parsed)
            expect(subject[:data]['new_licenses']).to match_array([a_hash_including('name' => 'BSD-4-Clause'),
              a_hash_including('name' => 'unknown')])
          end
        end

        context 'when querying compressed package metadata' do
          before do
            create(:pm_package, name: "nokogiri", purl_type: "gem",
              other_licenses: [{ license_names: ["BSD"], versions: ["1.8.0"] }])
          end

          it 'reports new licenses' do
            expect(subject[:status]).to eq(:parsed)
            expect(subject[:data]['new_licenses']).to match_array([a_hash_including('name' => 'BSD-4-Clause'),
              a_hash_including('name' => 'unknown')])
          end
        end
      end
    end

    context "when head pipeline has not run and base pipeline is for a forked project" do
      before do
        project.add_maintainer(maintainer)
        project.add_developer(contributor)
      end

      let(:service) { described_class.new(project, maintainer) }
      let(:maintainer) { create(:user) }
      let(:contributor) { create(:user) }
      let_it_be(:project) { create(:project, :public, :repository) }
      let(:base_pipeline) { nil }
      let(:head_pipeline) { create(:ee_ci_pipeline, :with_cyclonedx_report, project: forked_project, user: contributor) }
      let(:forked_project) { fork_project(project, contributor, namespace: contributor.namespace) }

      context 'when querying uncompressed package metadata' do
        before do
          stub_feature_flags(compressed_package_metadata_query: false)

          create(:pm_package_version_license, :with_all_relations, name: "nokogiri", purl_type: "gem", version: "1.8.0", license_name: "BSD")
        end

        it 'reports new licenses' do
          expect(subject[:status]).to eq(:parsed)
          expect(subject[:data]['new_licenses'].count).to eq(2)
        end
      end

      context 'when querying compressed package metadata' do
        before do
          create(:pm_package, name: "nokogiri", purl_type: "gem",
            other_licenses: [{ license_names: ["BSD"], versions: ["1.8.0"] }])
        end

        it 'reports new licenses' do
          expect(subject[:status]).to eq(:parsed)
          expect(subject[:data]['new_licenses'].count).to eq(2)
        end
      end
    end

    context 'when base and head pipelines have test reports' do
      context 'with license scanning reports' do
        let!(:base_pipeline) { create(:ee_ci_pipeline, :with_license_scanning_report, project: project) }
        let!(:head_pipeline) { create(:ee_ci_pipeline, :with_license_scanning_feature_branch, project: project) }

        it 'reports status as parsed' do
          expect(subject[:status]).to eq(:parsed)
        end

        it 'does not display results' do
          expect(subject[:data]['new_licenses']).to be_empty
          expect(subject[:data]['existing_licenses']).to be_empty
          expect(subject[:data]['removed_licenses']).to be_empty
        end
      end

      context 'with cyclonedx reports' do
        let!(:base_pipeline) { create(:ee_ci_pipeline, :with_cyclonedx_report, project: project) }
        let!(:head_pipeline) { create(:ee_ci_pipeline, :with_cyclonedx_pypi_only, project: project) }

        context 'when querying uncompressed package metadata' do
          before do
            stub_feature_flags(compressed_package_metadata_query: false)

            create(:pm_package_version_license, :with_all_relations, name: "nokogiri", purl_type: "gem", version: "1.8.0", license_name: "BSD")
            create(:pm_package_version_license, :with_all_relations, name: "nokogiri", purl_type: "gem", version: "1.8.0", license_name: "MIT")
            create(:pm_package_version_license, :with_all_relations, name: "django", purl_type: "pypi", version: "1.11.4", license_name: "BSD")
            create(:pm_package_version_license, :with_all_relations, name: "django", purl_type: "pypi", version: "1.11.4", license_name: "Apache-2.0")
          end

          it 'reports status as parsed' do
            expect(subject[:status]).to eq(:parsed)
          end

          it 'reports new licenses' do
            expect(subject[:data]['new_licenses']).to match([a_hash_including('name' => 'Apache 2.0 License')])
          end

          it 'reports existing licenses' do
            expect(subject[:data]['existing_licenses']).to match(
              [a_hash_including('name' => 'BSD-4-Clause'), a_hash_including('name' => 'unknown')]
            )
          end

          it 'reports removed licenses' do
            expect(subject[:data]['removed_licenses']).to match([a_hash_including('name' => 'MIT')])
          end
        end

        context 'when querying compressed package metadata' do
          before do
            create(:pm_package, name: "nokogiri", purl_type: "gem",
              other_licenses: [{ license_names: %w[BSD MIT], versions: ["1.8.0"] }])

            create(:pm_package, name: "django", purl_type: "pypi",
              other_licenses: [{ license_names: ["BSD", "Apache-2.0"], versions: ["1.11.4"] }])
          end

          it 'reports status as parsed' do
            expect(subject[:status]).to eq(:parsed)
          end

          it 'reports new licenses' do
            expect(subject[:data]['new_licenses']).to match([a_hash_including('name' => 'Apache 2.0 License')])
          end

          it 'reports existing licenses' do
            expect(subject[:data]['existing_licenses']).to match(
              [a_hash_including('name' => 'BSD-4-Clause'), a_hash_including('name' => 'unknown')]
            )
          end

          it 'reports removed licenses' do
            expect(subject[:data]['removed_licenses']).to match([a_hash_including('name' => 'MIT')])
          end
        end
      end
    end

    context 'when pipelines have corrupted reports' do
      let!(:base_pipeline) { build(:ee_ci_pipeline, :with_corrupted_cyclonedx_report, project: project) }
      let!(:head_pipeline) { build(:ee_ci_pipeline, :with_corrupted_cyclonedx_report, project: project) }

      context "when base and head pipeline have corrupted reports" do
        it 'does not expose parser errors' do
          expect(subject[:status]).to eq(:parsed)
        end
      end

      context "when the base pipeline is nil" do
        subject { service.execute(nil, head_pipeline) }

        it 'does not expose parser errors' do
          expect(subject[:status]).to eq(:parsed)
        end
      end
    end
  end
end
