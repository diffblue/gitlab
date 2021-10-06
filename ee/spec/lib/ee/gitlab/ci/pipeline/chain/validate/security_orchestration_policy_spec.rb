# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Chain::Validate::SecurityOrchestrationPolicy do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:security_orchestration_policy_configuration) { build(:security_orchestration_policy_configuration, project: project) }

  let(:pipeline) { build(:ci_empty_pipeline, user: user, project: project) }

  let(:ci_yaml) do
    <<-CI_YAML
    job:
      script: ls
    CI_YAML
  end

  let(:yaml_processor_result) do
    ::Gitlab::Ci::YamlProcessor.new(
      ci_yaml, {
        project: project,
        sha: pipeline.sha,
        user: user
      }
    ).execute
  end

  let(:command) do
    Gitlab::Ci::Pipeline::Chain::Command.new(
      project: project, current_user: user, yaml_processor_result: yaml_processor_result, save_incompleted: true
    )
  end

  let(:step) { described_class.new(pipeline, command) }

  describe '#perform' do
    subject(:warning_messages) { pipeline.warning_messages.map(&:content) }

    context 'when security policies feature is not licensed' do
      before do
        stub_licensed_features(security_orchestration_policies: false)
      end

      it 'does not return warning' do
        step.perform!

        expect(warning_messages).to be_empty
      end
    end

    context 'when security policies feature is licensed' do
      before do
        stub_licensed_features(security_orchestration_policies: true)
      end

      context 'when policy file is missing' do
        before do
          allow(security_orchestration_policy_configuration).to receive(:policy_configuration_exists?).and_return(false)
        end

        it 'returns warning' do
          step.perform!

          expect(warning_messages).to include('scan-execution-policy: policy not applied, .gitlab/security-policies/policy.yml file is missing')
        end
      end

      context 'when policy file is present' do
        before do
          allow(security_orchestration_policy_configuration).to receive(:policy_configuration_exists?).and_return(true)
        end

        context 'when policy file is invalid' do
          before do
            allow(security_orchestration_policy_configuration).to receive(:policy_configuration_valid?).and_return(false)
          end

          it 'returns warning' do
            step.perform!

            expect(warning_messages).to include('scan-execution-policy: policy not applied, .gitlab/security-policies/policy.yml file is invalid')
          end
        end

        context 'when policy file is valid' do
          before do
            allow(security_orchestration_policy_configuration).to receive(:policy_configuration_valid?).and_return(true)
          end

          it 'does not return warning' do
            step.perform!

            expect(warning_messages).to be_empty
          end
        end
      end
    end
  end
end
