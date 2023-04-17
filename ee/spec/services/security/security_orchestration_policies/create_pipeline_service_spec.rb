# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::SecurityOrchestrationPolicies::CreatePipelineService, feature_category: :security_policy_management do
  include AfterNextHelpers

  describe '#execute' do
    let_it_be_with_reload(:project) { create(:project, :repository) }
    let_it_be(:current_user) { project.first_owner }
    let_it_be(:branch) { project.default_branch }
    let_it_be(:license) { create(:license, plan: License::ULTIMATE_PLAN) }

    let(:service) do
      described_class.new(project: project, current_user: current_user, params: {
                            actions: actions, branch: branch
                          })
    end

    describe "#pipeline_scan_config" do
      subject { service.pipeline_scan_config }

      context "with pipeline scan types" do
        let(:actions) do
          [{ scan: "secret_detection" },
           { scan: "container_scanning" }]
        end

        specify do
          expect(subject.keys).to eq(%i[secret-detection-0 container-scanning-1])
        end
      end

      context "without pipeline scan types" do
        let(:actions) do
          [{ scan: "dast" }]
        end

        specify do
          expect(subject.keys).to be_empty
        end
      end
    end

    describe "#on_demand_scan_config" do
      subject { service.on_demand_config }

      context "with pipeline scan types" do
        let(:actions) do
          [{ scan: "secret_detection" },
           { scan: "container_scanning" }]
        end

        specify do
          expect(subject.keys).to be_empty
        end
      end

      context "without pipeline scan types" do
        let(:actions) do
          [{ scan: "dast" }]
        end

        specify do
          expect(subject.keys).to eq(%i[dast-on-demand-0])
        end
      end
    end

    describe "#execute" do
      subject { service.execute }

      let(:error_message) { "foobar" }

      let(:status) { subject[:status] }
      let(:payload) { subject[:payload] }
      let(:message) { subject[:message] }

      let(:pipeline_scan_pipeline) { payload[:pipeline_scan] }
      let(:on_demand_pipeline) { payload[:on_demand] }

      before do
        allow(License).to receive(:current).and_return(license)
        stub_licensed_features(cluster_image_scanning: true, container_scanning: true)
      end

      context "without actions" do
        let(:actions) { [] }

        it "errors" do
          expect(status).to be(:error)
        end

        it "does not create pipelines" do
          expect { subject }.not_to change(project.all_pipelines, :count)
        end
      end

      context "with scan pipeline actions" do
        let(:actions) do
          [{ scan: "secret_detection" },
           { scan: "container_scanning" }]
        end

        it "succeeds" do
          expect(status).to be(:success)
        end

        it "creates a single pipeline" do
          expect { subject }.to change(project.all_pipelines, :count).by(1)
        end

        it "creates a stage" do
          expect { subject }.to change(project.stages, :count).by(1)
        end

        it "returns the pipeline" do
          expect(payload).to eq(pipeline_scan: project.all_pipelines.last)
        end

        it "sets the pipeline ref to the branch" do
          expect(pipeline_scan_pipeline.ref).to eq(branch)
        end

        it "sets the pipeline source" do
          expect(pipeline_scan_pipeline.source).to eq("security_orchestration_policy")
        end
      end

      context "with on-demand action" do
        let(:actions) do
          [{ scan: "dast" }]
        end

        context "without associated DAST profile" do
          it "succeeds" do
            expect(status).to be(:success)
          end

          it "creates a single pipeline" do
            expect { subject }.to change(project.all_pipelines, :count).by(1)
          end

          it "creates a stage" do
            expect { subject }.to change(project.stages, :count).by(1)
          end

          it "creates a `test` stage" do
            subject
            expect(project.stages.last.name).to eq("test")
          end

          it "returns the pipeline" do
            expect(payload).to eq(on_demand: project.all_pipelines.last)
          end

          it "sets the pipeline ref to the branch" do
            expect(on_demand_pipeline.ref).to eq(branch)
          end

          it "sets the pipeline source" do
            expect(on_demand_pipeline.source).to eq("ondemand_dast_scan")
          end
        end

        context "with associated DAST profiles" do
          let!(:dast_site_profile) { create(:dast_site_profile, :with_dast_submit_field, project: project) }
          let!(:dast_scanner_profile) { create(:dast_scanner_profile, project: project, spider_timeout: 42, target_timeout: 21) }
          let!(:dast_profile) { create(:dast_profile, project: project, dast_site_profile: dast_site_profile, dast_scanner_profile: dast_scanner_profile) }

          let(:actions) do
            [{ scan: "dast",
               scanner_profile: dast_scanner_profile.name,
               site_profile: dast_site_profile.name }]
          end

          it "succeeds" do
            expect(status).to be(:success)
          end

          it "creates a single pipeline" do
            expect { subject }.to change(project.all_pipelines, :count).by(1)
          end

          it "creates a stage" do
            expect { subject }.to change(project.stages, :count).by(1)
          end

          it "creates a `dast` stage" do
            subject
            expect(project.stages.last.name).to eq("dast")
          end

          it "returns the pipeline" do
            expect(payload).to eq(on_demand: project.all_pipelines.last)
          end

          it "sets the pipeline ref to the branch" do
            expect(on_demand_pipeline.ref).to eq(branch)
          end

          it "sets the pipeline source" do
            expect(on_demand_pipeline.source).to eq("ondemand_dast_scan")
          end
        end
      end

      context "with scan pipeline and on-demand actions" do
        let(:actions) do
          [{ scan: "secret_detection" },
           { scan: "container_scanning" },
           { scan: "dast" }]
        end

        it "succeeds" do
          expect(status).to be(:success)
        end

        it "creates two pipelines" do
          expect { subject }.to change(project.all_pipelines, :count).by(2)
        end

        it "creates two stages" do
          expect { subject }.to change(project.stages, :count).by(2)
        end

        it "returns the pipelines" do
          expect(payload).to eq(pipeline_scan: project.all_pipelines.find_by!(source: Enums::Ci::Pipeline.sources[:security_orchestration_policy]),
                                on_demand: project.all_pipelines.find_by!(source: Enums::Ci::Pipeline.sources[:ondemand_dast_scan]))
        end

        it "sets the pipeline refs to the branch" do
          expect(payload.values.map(&:ref)).to all(eq(branch))
        end

        it "separates scan pipeline actions" do
          expect(pipeline_scan_pipeline.builds.pluck(:name)).to eq(%w[secret-detection-0 container-scanning-1])
        end

        it "separates on-demand actions" do
          expect(on_demand_pipeline.builds.pluck(:name)).to eq(%w[dast-on-demand-0])
        end

        context "when scan pipeline creation fails" do
          let(:invalid_pipeline) { create(:ci_pipeline, :invalid) }
          let(:on_demand_pipeline) { project.all_pipelines.find_by!(source: "ondemand_dast_scan") }

          before do
            response = ServiceResponse.error(message: "", payload: invalid_pipeline)
            allow(invalid_pipeline).to receive(:full_error_messages).and_return(error_message)
            allow(service).to receive(:execute_pipeline_scans).and_return(response)
          end

          it "errors" do
            expect(status).to be(:error)
          end

          it "sets the pipeline error message" do
            expect(message).to eq(error_message)
          end

          it "creates the on-demand pipeline" do
            subject
            expect(project.all_pipelines).to contain_exactly(on_demand_pipeline)
          end
        end

        context "when on-demand pipeline creation fails" do
          before do
            response = ServiceResponse.error(message: error_message)
            allow(service).to receive(:execute_on_demand_scans).and_return(response)
          end

          let(:pipeline_scan_pipeline) { project.all_pipelines.find_by!(source: "security_orchestration_policy") }

          it "errors" do
            expect(status).to be(:error)
          end

          it "sets the error message" do
            expect(message).to eq(error_message)
          end

          it "creates the scan pipeline" do
            subject
            expect(project.all_pipelines).to contain_exactly(pipeline_scan_pipeline)
          end
        end

        context "when created on-demand pipeline is in error state" do
          let(:invalid_pipeline) { create(:ci_pipeline, :invalid) }
          let(:pipeline_scan_pipeline) { project.all_pipelines.find_by!(source: "security_orchestration_policy") }

          before do
            response = ServiceResponse.success(payload: invalid_pipeline)
            allow(invalid_pipeline).to receive(:full_error_messages).and_return(error_message)
            allow(service).to receive(:execute_on_demand_scans).and_return(response)
          end

          it "errors" do
            expect(status).to be(:error)
          end

          it "sets the error message" do
            expect(message).to eq(error_message)
          end

          it "creates the scan pipeline" do
            subject
            expect(project.all_pipelines).to contain_exactly(pipeline_scan_pipeline)
          end
        end
      end

      describe 'secret_detection scan action' do
        let(:actions) do
          [{ scan: 'secret_detection' }]
        end

        let(:most_recent_commit_sha) { project.repository.commit(branch).sha }

        shared_examples 'creates a build with appropriate variables' do
          it 'creates a build with appropriate variables' do
            build = pipeline_scan_pipeline.builds.first
            expect(build.variables.to_runner_variables).to include(*expected_variables)
          end
        end

        context 'without a previous scan' do
          let(:expected_variables) { [{ key: 'SECRET_DETECTION_HISTORIC_SCAN', value: 'true', public: true, masked: false }] }

          it_behaves_like 'creates a build with appropriate variables'
        end

        context 'with a previous scan' do
          let(:last_scan_pipeline_sha) { '0beec7b5ea3f0fdbc95d0dd47f3c5bc275da8a33' }
          let(:last_scan_pipeline) do
            create(:ci_pipeline, :success,
                   project: project,
                   ref: branch,
                   source: :security_orchestration_policy,
                   sha: last_scan_pipeline_sha)
          end

          let(:most_recent_commit_sha) { project.repository.commit(branch).sha }

          let(:expected_variables) do
            [
              {
                key: 'SECRET_DETECTION_LOG_OPTS',
                value: "#{last_scan_pipeline_sha}..#{most_recent_commit_sha}",
                public: true,
                masked: false
              }
            ]
          end

          before do
            create(:security_scan, :latest_successful, scan_type: :secret_detection, pipeline: last_scan_pipeline, project: project)
          end

          it_behaves_like 'creates a build with appropriate variables'

          context 'with scans in multiple branches' do
            let(:other_branch) { project.repository.create_branch('other_branch', project.default_branch) }

            let(:last_scan_pipeline_other_branch_sha) { '570e7b2abdd848b95f2f578043fc23bd6f6fd24d' }
            let(:last_scan_pipeline_other_branch) do
              create(:ci_pipeline, :success,
                     project: project,
                     ref: other_branch,
                     source: :security_orchestration_policy,
                     sha: last_scan_pipeline_sha)
            end

            before do
              create(:security_scan, :latest_successful, scan_type: :secret_detection, pipeline: last_scan_pipeline_other_branch, project: project)
            end

            it_behaves_like 'creates a build with appropriate variables'
          end
        end
      end

      describe "sast scan action" do
        let(:actions) do
          [{ scan: 'sast',
             variables: { SAST_EXCLUDED_ANALYZERS: 'semgrep' } }]
        end

        context "when action contains variables" do
          it 'parses variables from the action and applies them in configuration service' do
            expect_next_instance_of(::Security::SecurityOrchestrationPolicies::CiConfigurationService) do |ci_configuration_service|
              expect(ci_configuration_service).to receive(:execute).once
                                                    .with(actions.first, { 'SAST_EXCLUDED_ANALYZERS' => 'semgrep' }, 0).and_call_original
            end

            subject
          end
        end
      end

      context "when project has a compliance framework" do
        let(:compliance_group) { create(:group, :private, name: "compliance") }
        let(:compliance_project) { create(:project, :repository, namespace: compliance_group, name: "hippa") }
        let(:framework) { create(:compliance_framework, namespace_id: compliance_group.id, pipeline_configuration_full_path: ".compliance-gitlab-ci.yml@compliance/hippa") }
        let!(:framework_project_setting) { create(:compliance_framework_project_setting, project: project, framework_id: framework.id) }
        let!(:ref_sha) { compliance_project.commit('HEAD').sha }

        let(:actions) do
          [{ scan: "container_scanning" }]
        end

        let(:compliance_config) do
          <<~EOY
            ---
            compliance_build:
              stage: build
              script:
                - echo 'hello from compliance build'
            compliance_test:
              stage: test
              script:
                - echo 'hello from compliance test'
          EOY
        end

        before do
          project.update_attribute(:namespace_id, compliance_group.id)
          compliance_project.add_maintainer(current_user)
          stub_licensed_features(cluster_image_scanning: true, container_scanning: true, evaluate_group_level_compliance_pipeline: true)
          allow_next(Repository).to receive(:blob_data_at).with(ref_sha, '.compliance-gitlab-ci.yml').and_return(compliance_config)
        end

        it 'does not include the compliance definition' do
          subject

          yaml = YAML.safe_load(pipeline_scan_pipeline.pipeline_config.content, permitted_classes: [Symbol])
          expect(yaml).not_to eq("include" => [{ "file" => ".compliance-gitlab-ci.yml", "project" => "compliance/hippa" }])
        end
      end
    end
  end
end
