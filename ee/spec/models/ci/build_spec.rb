# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Build, :saas, feature_category: :continuous_integration do
  let_it_be(:group) { create(:group_with_plan, plan: :bronze_plan) }

  let(:project) { create(:project, :repository, group: group) }

  let(:pipeline) do
    create(
      :ci_pipeline,
      project: project,
      sha: project.commit.id,
      ref: project.default_branch,
      status: 'success'
    )
  end

  let(:job) { create(:ci_build, pipeline: pipeline) }
  let(:artifact) { create(:ee_ci_job_artifact, :sast, job: job, project: job.project) }
  let_it_be(:valid_secrets) do
    {
      DATABASE_PASSWORD: {
        vault: {
          engine: { name: 'kv-v2', path: 'kv-v2' },
          path: 'production/db',
          field: 'password'
        }
      }
    }
  end

  it_behaves_like 'has secrets', :ci_build

  describe '.license_scan' do
    subject(:build) { described_class.license_scan.first }

    let(:artifact) { build.job_artifacts.first }

    context 'with new license_scanning artifact' do
      let!(:license_artifact) { create(:ee_ci_job_artifact, :license_scanning, job: job, project: job.project) }

      it { expect(artifact.file_type).to eq 'license_scanning' }
    end
  end

  describe 'clone_accessors' do
    it 'includes the cloneable extra accessors' do
      expect(::Ci::Build.clone_accessors).to include(:secrets)
    end
  end

  describe 'associations' do
    it { is_expected.to have_many(:security_scans).class_name('Security::Scan').with_foreign_key(:build_id) }
    it { is_expected.to have_one(:dast_site_profiles_build).class_name('Dast::SiteProfilesBuild').with_foreign_key(:ci_build_id) }
    it { is_expected.to have_one(:dast_site_profile).class_name('DastSiteProfile').through(:dast_site_profiles_build) }
    it { is_expected.to have_one(:dast_scanner_profiles_build).class_name('Dast::ScannerProfilesBuild').with_foreign_key(:ci_build_id) }
    it { is_expected.to have_one(:dast_scanner_profile).class_name('DastScannerProfile').through(:dast_scanner_profiles_build) }
  end

  describe '#cost_factor_enabled?' do
    subject { job.cost_factor_enabled? }

    before do
      allow(::Gitlab::CurrentSettings).to receive(:shared_runners_minutes) { 400 }
    end

    context 'with shared runner' do
      before do
        job.runner = create(:ci_runner, :instance)
      end

      it { is_expected.to be_truthy }
    end

    context 'with project runner' do
      before do
        job.runner = create(:ci_runner, :project)
      end

      it { is_expected.to be_falsey }
    end

    context 'without runner' do
      it { is_expected.to be_falsey }
    end
  end

  describe 'updates pipeline minutes' do
    let(:job) { create(:ci_build, :running, pipeline: pipeline) }

    %w(success drop cancel).each do |event|
      it "for event #{event}" do
        expect(Ci::Minutes::UpdateBuildMinutesService)
          .to receive(:new).and_call_original

        job.public_send(event)
      end
    end
  end

  describe '#variables' do
    subject { job.variables }

    context 'when environment specific variable is defined' do
      let(:environment_variable) do
        { key: 'ENV_KEY', value: 'environment', public: false, masked: false }
      end

      before do
        job.update!(environment: 'staging')
        create(:environment, name: 'staging', project: job.project)

        variable = build(
          :ci_variable,
          environment_variable.slice(:key, :value).merge(project: project, environment_scope: 'stag*')
        )

        variable.save!
      end

      context 'when there is a plan for the group' do
        it 'GITLAB_FEATURES should include the features for that plan' do
          expect(subject.to_runner_variables).to include({ key: 'GITLAB_FEATURES', value: anything, public: true, masked: false })
          features_variable = subject.find { |v| v[:key] == 'GITLAB_FEATURES' }
          expect(features_variable[:value]).to include('multiple_ldap_servers')
        end
      end

      describe 'dast' do
        let_it_be(:project) { create(:project, :repository) }
        let_it_be(:user) { create(:user, developer_projects: [project]) }
        let_it_be(:dast_site_profile) { create(:dast_site_profile, project: project) }
        let_it_be(:dast_scanner_profile) { create(:dast_scanner_profile, project: project) }
        let_it_be(:dast_site_profile_secret_variable) { create(:dast_site_profile_secret_variable, :password, dast_site_profile: dast_site_profile) }
        let_it_be(:options) { { dast_configuration: { site_profile: dast_site_profile.name, scanner_profile: dast_scanner_profile.name } } }

        before do
          stub_licensed_features(security_on_demand_scans: true)
        end

        shared_examples 'it includes variables' do
          it 'includes variables from the profile' do
            expect(subject.to_runner_variables).to include(*expected_variables.to_runner_variables)
          end
        end

        shared_examples 'it excludes variables' do
          it 'excludes variables from the profile' do
            expect(subject.to_runner_variables).not_to include(*expected_variables.to_runner_variables)
          end
        end

        context 'when there is a dast_site_profile associated with the job' do
          let(:pipeline) { create(:ci_pipeline, project: project) }
          let(:job) { create(:ci_build, :running, pipeline: pipeline, dast_site_profile: dast_site_profile, user: user, options: options) }

          it_behaves_like 'it includes variables' do
            let(:expected_variables) { dast_site_profile.ci_variables }
          end

          context 'when user has permission' do
            it_behaves_like 'it includes variables' do
              let(:expected_variables) { dast_site_profile.secret_ci_variables(user) }
            end
          end
        end

        context 'when there is a dast_scanner_profile associated with the job' do
          let(:pipeline) { create(:ci_pipeline, project: project, user: user) }
          let(:job) { create(:ci_build, :running, pipeline: pipeline, dast_scanner_profile: dast_scanner_profile, options: options) }

          it_behaves_like 'it includes variables' do
            let(:expected_variables) { dast_scanner_profile.ci_variables }
          end
        end

        context 'when there are profiles associated with the job' do
          let(:pipeline) { create(:ci_pipeline, project: project) }
          let(:job) { create(:ci_build, :running, pipeline: pipeline, dast_site_profile: dast_site_profile, dast_scanner_profile: dast_scanner_profile, user: user, options: options) }

          context 'when dast_configuration is absent from the options' do
            let(:options) { {} }

            it 'does not attempt look up any dast profiles to avoid unnecessary queries', :aggregate_failures do
              expect(job).not_to receive(:dast_site_profile)
              expect(job).not_to receive(:dast_scanner_profile)

              subject
            end
          end

          context 'when site_profile is absent from the dast_configuration' do
            let(:options) { { dast_configuration: { scanner_profile: dast_scanner_profile.name } } }

            it 'does not attempt look up the site profile to avoid unnecessary queries' do
              expect(job).not_to receive(:dast_site_profile)

              subject
            end
          end

          context 'when scanner_profile is absent from the dast_configuration' do
            let(:options) { { dast_configuration: { site_profile: dast_site_profile.name } } }

            it 'does not attempt look up the scanner profile to avoid unnecessary queries' do
              expect(job).not_to receive(:dast_scanner_profile)

              subject
            end
          end

          context 'when both profiles are present in the dast_configuration' do
            it 'attempts look up dast profiles', :aggregate_failures do
              expect(job).to receive(:dast_site_profile).and_call_original.at_least(:once)
              expect(job).to receive(:dast_scanner_profile).and_call_original.at_least(:once)

              subject
            end

            context 'when dast_site_profile target_type is website' do
              it_behaves_like 'it includes variables' do
                let(:expected_variables) { dast_scanner_profile.ci_variables(dast_site_profile: dast_site_profile) }
              end
            end

            context 'when dast_site_profile target_type is api' do
              let_it_be(:dast_site_profile) { create(:dast_site_profile, project: project, target_type: 'api') }

              it_behaves_like 'it includes variables' do
                let(:expected_variables) { dast_scanner_profile.ci_variables(dast_site_profile: dast_site_profile) }
              end
            end
          end
        end
      end
    end

    describe 'variable CI_HAS_OPEN_REQUIREMENTS' do
      it "is included with value 'true' if there are open requirements" do
        create(:work_item, :requirement, project: project)

        expect(subject).to include({ key: 'CI_HAS_OPEN_REQUIREMENTS',
                                     value: 'true', public: true, masked: false })
      end

      it 'is not included if there are no open requirements' do
        create(:work_item, :requirement, project: project, state: :closed)

        requirement_variable = subject.find { |var| var[:key] == 'CI_HAS_OPEN_REQUIREMENTS' }

        expect(requirement_variable).to be_nil
      end
    end
  end

  describe '#has_security_reports?' do
    subject { job.has_security_reports? }

    context 'when build has a security report' do
      let!(:artifact) { create(:ee_ci_job_artifact, :sast, job: job, project: job.project) }

      it { is_expected.to be true }
    end

    context 'when build does not have a security report' do
      it { is_expected.to be false }
    end
  end

  describe '#unmerged_security_reports' do
    subject(:security_reports) { job.unmerged_security_reports }

    context 'when build has a security report' do
      context 'when there is a sast report' do
        let!(:artifact) { create(:ee_ci_job_artifact, :sast, job: job, project: job.project) }

        it 'parses blobs and add the results to the report' do
          expect(security_reports.get_report('sast', artifact).findings.size).to eq(5)
        end
      end

      context 'when there are multiple reports' do
        let!(:sast_artifact) { create(:ee_ci_job_artifact, :sast, job: job, project: job.project) }
        let!(:ds_artifact) { create(:ee_ci_job_artifact, :dependency_scanning, job: job, project: job.project) }
        let!(:cs_artifact) { create(:ee_ci_job_artifact, :container_scanning, job: job, project: job.project) }
        let!(:dast_artifact) { create(:ee_ci_job_artifact, :dast, job: job, project: job.project) }

        it 'parses blobs and adds unmerged results to the reports' do
          expect(security_reports.get_report('sast', sast_artifact).findings.size).to eq(5)
          expect(security_reports.get_report('dependency_scanning', ds_artifact).findings.size).to eq(4)
          expect(security_reports.get_report('container_scanning', cs_artifact).findings.size).to eq(8)
          expect(security_reports.get_report('dast', dast_artifact).findings.size).to eq(24)
        end
      end
    end

    context 'when build has no security reports' do
      it 'has no parsed reports' do
        expect(security_reports.reports).to be_empty
      end
    end
  end

  describe '#collect_security_reports!' do
    let(:security_reports) { ::Gitlab::Ci::Reports::Security::Reports.new(pipeline) }

    before do
      stub_licensed_features(sast: true, dependency_scanning: true, container_scanning: true, dast: true)
    end

    context 'when report types are given' do
      let!(:ds_artifact) { create(:ee_ci_job_artifact, :dependency_scanning, job: job, project: job.project) }
      let!(:cs_artifact) { create(:ee_ci_job_artifact, :container_scanning, job: job, project: job.project) }

      subject { job.collect_security_reports!(security_reports, report_types: %w[container_scanning]) }

      it 'parses blobs and add the results for given report types' do
        subject

        expect(security_reports.get_report('dependency_scanning', ds_artifact).findings.size).to eq(0)
        expect(security_reports.get_report('container_scanning', cs_artifact).findings.size).to eq(8)
      end
    end

    context 'when report types are not given' do
      subject { job.collect_security_reports!(security_reports) }

      context 'when build has a security report' do
        context 'when there is a sast report' do
          let!(:artifact) { create(:ee_ci_job_artifact, :sast, job: job, project: job.project) }

          it 'parses blobs and add the results to the report' do
            subject

            expect(security_reports.get_report('sast', artifact).findings.size).to eq(5)
          end

          it 'adds the created date to the report' do
            subject

            expect(security_reports.get_report('sast', artifact).created_at.to_s).to eq(artifact.created_at.to_s)
          end
        end

        context 'when there are multiple reports' do
          let!(:sast_artifact) { create(:ee_ci_job_artifact, :sast, job: job, project: job.project) }
          let!(:ds_artifact) { create(:ee_ci_job_artifact, :dependency_scanning, job: job, project: job.project) }
          let!(:cs_artifact) { create(:ee_ci_job_artifact, :container_scanning, job: job, project: job.project) }
          let!(:dast_artifact) { create(:ee_ci_job_artifact, :dast, job: job, project: job.project) }

          it 'parses blobs and adds the results to the reports' do
            subject

            expect(security_reports.get_report('sast', sast_artifact).findings.size).to eq(5)
            expect(security_reports.get_report('dependency_scanning', ds_artifact).findings.size).to eq(4)
            expect(security_reports.get_report('container_scanning', cs_artifact).findings.size).to eq(8)
            expect(security_reports.get_report('dast', dast_artifact).findings.size).to eq(20)
          end
        end

        context 'when there is a corrupted sast report' do
          let!(:artifact) { create(:ee_ci_job_artifact, :sast_with_corrupted_data, job: job, project: job.project) }

          it 'stores an error' do
            subject

            expect(security_reports.get_report('sast', artifact)).to be_errored
          end
        end

        describe 'vulnerability_finding_signatures' do
          let!(:artifact) { create(:ee_ci_job_artifact, :sast, job: job, project: job.project) }

          where(signatures_enabled: [true, false])
          with_them do
            it 'parses the report' do
              stub_licensed_features(
                sast: true,
                vulnerability_finding_signatures: signatures_enabled
              )

              expect(::Gitlab::Ci::Parsers::Security::Sast).to receive(:new).with(
                artifact.file.read,
                kind_of(::Gitlab::Ci::Reports::Security::Report),
                signatures_enabled: signatures_enabled
              )

              subject
            end
          end
        end
      end

      context 'when there is unsupported file type' do
        let!(:artifact) { create(:ee_ci_job_artifact, :codequality, job: job, project: job.project) }

        before do
          stub_const("Ci::JobArtifact::SECURITY_REPORT_FILE_TYPES", %w[codequality])
        end

        it 'stores an error' do
          subject

          expect(security_reports.get_report('codequality', artifact)).to be_errored
        end
      end
    end
  end

  describe '#collect_license_scanning_reports!' do
    subject { job.collect_license_scanning_reports!(license_scanning_report) }

    let(:license_scanning_report) { build(:license_scanning_report) }

    it { expect(license_scanning_report.licenses.count).to eq(0) }

    context 'when the build has a license scanning report' do
      before do
        stub_licensed_features(license_scanning: true)
      end

      context 'when there is a report' do
        before do
          create(:ee_ci_job_artifact, :license_scanning, job: job, project: job.project)
        end

        it 'parses blobs and add the results to the report' do
          expect { subject }.not_to raise_error

          expect(license_scanning_report.licenses.count).to eq(4)
          expect(license_scanning_report.licenses.map(&:name)).to contain_exactly("Apache 2.0", "MIT", "New BSD", "unknown")
          expect(license_scanning_report.licenses.find { |x| x.name == 'MIT' }.dependencies.count).to eq(52)
        end
      end

      context 'when there is a corrupted report' do
        before do
          create(:ee_ci_job_artifact, :license_scan, :with_corrupted_data, job: job, project: job.project)
        end

        it 'returns an empty report' do
          expect { subject }.not_to raise_error
          expect(license_scanning_report).to be_empty
        end
      end

      context 'when the license scanning feature is disabled' do
        before do
          stub_licensed_features(license_scanning: false)
          create(:ee_ci_job_artifact, :license_scanning, job: job, project: job.project)
        end

        it 'does NOT parse license scanning report' do
          subject

          expect(license_scanning_report.licenses.count).to eq(0)
        end
      end
    end
  end

  describe '#collect_dependency_list_reports!' do
    let!(:dl_artifact) { create(:ee_ci_job_artifact, :dependency_list, job: job, project: job.project) }
    let(:dependency_list_report) { Gitlab::Ci::Reports::DependencyList::Report.new }

    subject { job.collect_dependency_list_reports!(dependency_list_report) }

    context 'with available licensed feature' do
      before do
        stub_licensed_features(dependency_scanning: true)
      end

      it 'parses blobs and add the results to the report' do
        subject
        blob_path = "/#{project.full_path}/-/blob/#{job.sha}/yarn/yarn.lock"
        mini_portile2 = dependency_list_report.dependencies[0]
        yarn = dependency_list_report.dependencies[20]

        expect(dependency_list_report.dependencies.count).to eq(21)
        expect(mini_portile2[:name]).to eq('mini_portile2')
        expect(yarn[:location][:blob_path]).to eq(blob_path)
      end
    end

    context 'with different report format' do
      let!(:dl_artifact) { create(:ee_ci_job_artifact, :dependency_scanning, job: job, project: job.project) }
      let(:dependency_list_report) { Gitlab::Ci::Reports::DependencyList::Report.new }

      before do
        stub_licensed_features(dependency_scanning: true)
      end

      subject { job.collect_dependency_list_reports!(dependency_list_report) }

      it 'parses blobs and add the results to the report' do
        subject

        expect(dependency_list_report.dependencies.count).to eq(0)
      end
    end

    context 'with disabled licensed feature' do
      it 'does NOT parse dependency list report' do
        subject

        expect(dependency_list_report.dependencies).to be_empty
      end
    end
  end

  describe '#collect_metrics_reports!' do
    subject { job.collect_metrics_reports!(metrics_report) }

    let(:metrics_report) { Gitlab::Ci::Reports::Metrics::Report.new }

    context 'when there is a metrics report' do
      before do
        create(:ee_ci_job_artifact, :metrics, job: job, project: job.project)
      end

      context 'when license has metrics_reports' do
        before do
          stub_licensed_features(metrics_reports: true)
        end

        it 'parses blobs and add the results to the report' do
          expect { subject }.to change { metrics_report.metrics.count }.from(0).to(2)
        end
      end

      context 'when license does not have metrics_reports' do
        before do
          stub_licensed_features(license_scanning: false)
        end

        it 'does not parse metrics report' do
          subject

          expect(metrics_report.metrics.count).to eq(0)
        end
      end
    end
  end

  describe '#collect_requirements_reports!' do
    subject { job.collect_requirements_reports!(requirements_report) }

    let(:requirements_report) { Gitlab::Ci::Reports::RequirementsManagement::Report.new }

    context 'when there is a requirements report' do
      before do
        create(:ee_ci_job_artifact, :all_passing_requirements_v2, job: job, project: job.project)
      end

      context 'when requirements are available' do
        before do
          stub_licensed_features(requirements: true)
        end

        it 'parses blobs and adds the results to the report' do
          expect { subject }.to change { requirements_report.requirements.count }.from(0).to(1)
          expect(requirements_report.requirements).to eq({ "*" => "passed" })
        end
      end

      context 'when requirements are not available' do
        before do
          stub_licensed_features(requirements: false)
        end

        it 'does not parse requirements report' do
          subject

          expect(requirements_report.requirements.count).to eq(0)
        end
      end
    end

    context 'when using legacy format' do
      subject { job.collect_requirements_reports!(requirements_report, legacy: true) }

      context 'when there is a requirements report' do
        before do
          create(:ee_ci_job_artifact, :all_passing_requirements, job: job, project: job.project)
        end

        context 'when requirements are available' do
          before do
            stub_licensed_features(requirements: true)
          end

          it 'parses blobs and adds the results to the report' do
            expect { subject }.to change { requirements_report.requirements.count }.from(0).to(1)
          end
        end

        context 'when requirements are not available' do
          before do
            stub_licensed_features(requirements: false)
          end

          it 'does not parse requirements report' do
            subject

            expect(requirements_report.requirements.count).to eq(0)
          end
        end
      end
    end
  end

  describe '#collect_sbom_reports!' do
    subject { job.collect_sbom_reports!(sbom_reports_list) }

    let(:sbom_reports_list) { Gitlab::Ci::Reports::Sbom::Reports.new }

    context 'when there is an sbom report' do
      let!(:cyclonedx_artifact) { create(:ee_ci_job_artifact, :cyclonedx, job: job, project: job.project) }

      it 'adds each report to the reports list and parses it' do
        subject

        aggregate_failures do
          expect(sbom_reports_list.reports.count).to eq(4)
          expect(sbom_reports_list.reports[0].components.count).to eq(46)
          expect(sbom_reports_list.reports[1].components.count).to eq(15)
          expect(sbom_reports_list.reports[2].components.count).to eq(28)
          expect(sbom_reports_list.reports[3].components.count).to eq(352)
        end
      end
    end
  end

  describe '#retryable?' do
    subject { build.retryable? }

    let(:pipeline) { merge_request.all_pipelines.last }
    let!(:build) { create(:ci_build, :canceled, pipeline: pipeline) }

    context 'with pipeline for merged results' do
      let(:merge_request) { create(:merge_request, :with_merge_request_pipeline) }

      it { is_expected.to be true }
    end
  end

  describe ".license_scan" do
    it 'returns only license artifacts' do
      create(:ci_build, job_artifacts: [create(:ci_job_artifact, :zip)])
      build_with_license_scan = create(:ci_build, job_artifacts: [create(:ci_job_artifact, file_type: :license_scanning, file_format: :raw)])

      expect(described_class.license_scan).to contain_exactly(build_with_license_scan)
    end
  end

  describe ".sbom_generation" do
    it 'returns only cyclonedx sbom artifacts' do
      create(:ci_build, job_artifacts: [create(:ci_job_artifact, :zip)])
      build_with_cyclonedx_sbom = create(:ci_build, job_artifacts: [create(:ee_ci_job_artifact, :cyclonedx)])

      expect(described_class.sbom_generation).to contain_exactly(build_with_cyclonedx_sbom)
    end
  end

  describe 'ci_secrets_management_available?' do
    subject { job.ci_secrets_management_available? }

    context 'when build has no project' do
      before do
        job.update!(project: nil)
      end

      it { is_expected.to be false }
    end

    context 'when secrets management feature is available' do
      before do
        stub_licensed_features(ci_secrets_management: true)
      end

      it { is_expected.to be true }
    end

    context 'when secrets management feature is not available' do
      before do
        stub_licensed_features(ci_secrets_management: false)
      end

      it { is_expected.to be false }
    end
  end

  describe '#runner_required_feature_names' do
    let(:build) { create(:ci_build, secrets: secrets) }

    subject { build.runner_required_feature_names }

    context 'when secrets management feature is available' do
      before do
        stub_licensed_features(ci_secrets_management: true)
      end

      context 'when there are secrets defined' do
        let(:secrets) { valid_secrets }

        it { is_expected.to include(:vault_secrets) }
      end

      context 'when there are no secrets defined' do
        let(:secrets) { {} }

        it { is_expected.not_to include(:vault_secrets) }
      end
    end

    context 'when secrets management feature is not available' do
      before do
        stub_licensed_features(ci_secrets_management: false)
      end

      context 'when there are secrets defined' do
        let(:secrets) { valid_secrets }

        it { is_expected.not_to include(:vault_secrets) }
      end

      context 'when there are no secrets defined' do
        let(:secrets) { {} }

        it { is_expected.not_to include(:vault_secrets) }
      end
    end
  end

  describe 'secrets management usage data' do
    let_it_be(:user) { create(:user) }

    context 'when secrets management feature is not available' do
      before do
        stub_licensed_features(ci_secrets_management: false)
      end

      it 'does not track RedisHLL event' do
        expect(::Gitlab::UsageDataCounters::HLLRedisCounter).not_to receive(:track_event)

        create(:ci_build, secrets: valid_secrets)
      end

      it 'does not track Snowplow event' do
        create(:ci_build, secrets: valid_secrets)

        expect_no_snowplow_event
      end
    end

    context 'when secrets management feature is available' do
      before do
        stub_licensed_features(ci_secrets_management: true)
      end

      context 'when there are secrets defined' do
        context 'on create' do
          let(:ci_build) { build(:ci_build, secrets: valid_secrets, user: user) }

          it 'tracks RedisHLL event with user_id' do
            expect(::Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:track_event)
              .with('i_ci_secrets_management_vault_build_created', values: user.id)

            ci_build.save!
          end

          it 'tracks Snowplow event with RedisHLL context' do
            params = {
              category: described_class.to_s,
              action: 'create_secrets_vault',
              namespace: ci_build.namespace,
              user: user,
              label: 'redis_hll_counters.ci_secrets_management.i_ci_secrets_management_vault_build_created_monthly',
              ultimate_namespace_id: ci_build.namespace.root_ancestor.id,
              context: [::Gitlab::Tracking::ServicePingContext.new(
                data_source: :redis_hll,
                event: 'i_ci_secrets_management_vault_build_created'
              ).to_context.to_json]
            }

            ci_build.save!

            expect_snowplow_event(**params)
          end

          context 'with usage_data_i_ci_secrets_management_vault_build_created FF disabled' do
            before do
              stub_feature_flags(usage_data_i_ci_secrets_management_vault_build_created: false)
            end

            it 'does not track RedisHLL event' do
              # Events FF are checked inside track_event, so need to verify it on the next level
              expect(::Gitlab::Redis::HLL).not_to receive(:add)

              ci_build.save!
            end

            it 'does not track Snowplow event' do
              ci_build.save!

              expect_no_snowplow_event
            end
          end
        end

        context 'on update' do
          let_it_be(:ci_build) { create(:ci_build, secrets: valid_secrets, user: user) }

          it 'does not track RedisHLL event' do
            expect(::Gitlab::UsageDataCounters::HLLRedisCounter).not_to receive(:track_event)

            ci_build.success
          end

          it 'does not track Snowplow event' do
            ci_build.success

            expect_no_snowplow_event
          end
        end
      end
    end

    context 'when there are no secrets defined' do
      let(:ci_build) { build(:ci_build, user: user) }

      context 'on create' do
        it 'does not track RedisHLL event' do
          expect(::Gitlab::UsageDataCounters::HLLRedisCounter).not_to receive(:track_event)

          ci_build.save!
        end

        it 'does not track Snowplow event' do
          ci_build.save!

          expect_no_snowplow_event
        end
      end
    end
  end
end
