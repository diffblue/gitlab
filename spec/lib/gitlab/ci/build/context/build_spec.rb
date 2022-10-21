# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Build::Context::Build do
  let(:pipeline)        { create(:ci_pipeline) }
  let(:seed_attributes) { { 'name' => 'some-job' } }

  let(:context) { described_class.new(pipeline, seed_attributes) }

  shared_examples 'variables collection' do
    it { is_expected.to include('CI_COMMIT_REF_NAME' => 'master') }
    it { is_expected.to include('CI_PIPELINE_IID'    => pipeline.iid.to_s) }
    it { is_expected.to include('CI_PROJECT_PATH'    => pipeline.project.full_path) }
    it { is_expected.to include('CI_JOB_NAME'        => 'some-job') }
    it { is_expected.to include('CI_BUILD_REF_NAME'  => 'master') }

    context 'without passed build-specific attributes' do
      let(:context) { described_class.new(pipeline) }

      it { is_expected.to include('CI_JOB_NAME'       => nil) }
      it { is_expected.to include('CI_BUILD_REF_NAME' => 'master') }
      it { is_expected.to include('CI_PROJECT_PATH'   => pipeline.project.full_path) }
    end
  end

  describe '#variables' do
    subject { context.variables.to_hash }

    it { expect(context.variables).to be_instance_of(Gitlab::Ci::Variables::Collection) }

    it_behaves_like 'variables collection'
  end

  describe '#variables_hash' do
    subject { context.variables_hash }

    it { expect(context.variables_hash).to be_instance_of(ActiveSupport::HashWithIndifferentAccess) }

    it_behaves_like 'variables collection'
  end

  describe "scan-variable sanitization" do
    subject { context.variables.to_hash }

    let(:project) { pipeline.project }
    let(:overrides) { described_class::VARIABLE_OVERRIDES }

    context "when project has scan-skipping CI variables configured" do
      before do
        project.variables.insert_all(overrides.map { |k, v| { key: k, value: "true" } })
      end

      context "with feature disabled" do
        it "does not sanitize variables" do
          expect(subject).to include("CONTAINER_SCANNING_DISABLED")
        end
      end

      context "with feature enabled" do
        before do
          allow(project).to receive(:feature_available?).with(:security_orchestration_policies).and_return(true)
        end

        context "with active scan execution policies" do
          let(:policy_configuration) { create(:security_orchestration_policy_configuration, project: project) }

          let(:policy_hash) do
            { scan_execution_policy: [{ name: "Test policy",
                                        description: "",
                                        enabled: true,
                                        actions: [{ scan: "secret_detection" }],
                                        rules: [{ type: "pipeline", branches: ["*"] }] }] }
          end

          before do
            allow(policy_configuration).to receive(:policy_hash).and_return(policy_hash)
          end

          it 'sanitizes variables' do
            expect(subject).not_to include("CONTAINER_SCANNING_DISABLED")
          end

          it 'overrides variables' do
            expect(subject).to include("SECRET_DETECTION_HISTORIC_SCAN" => "false")
          end
        end

        context "without active scan execution policies" do
          it "does not sanitize variables" do
            expect(subject).to include("CONTAINER_SCANNING_DISABLED")
          end
        end
      end
    end
  end
end
