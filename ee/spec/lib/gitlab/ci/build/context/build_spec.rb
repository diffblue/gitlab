# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Build::Context::Build do
  let(:pipeline)        { create(:ci_pipeline) }
  let(:seed_attributes) { { 'name' => 'some-job' } }

  let(:context) { described_class.new(pipeline, seed_attributes) }

  describe "scan-variable sanitization" do
    subject { context.variables.to_hash }

    let(:project) { pipeline.project }
    let(:overrides) { described_class::VARIABLE_OVERRIDES }

    context "when project has scan-skipping CI variables configured" do
      before do
        project.variables.insert_all(overrides.map { |k, v| { key: k, value: "true" } }) if overrides.any?
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
