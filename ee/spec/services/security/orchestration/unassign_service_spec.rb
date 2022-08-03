# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::Orchestration::UnassignService do
  describe '#execute' do
    subject(:result) { service.execute }

    shared_examples 'unassigns policy project' do
      context 'when policy project is assigned to a project or namespace' do
        let(:service) { described_class.new(container: container, current_user: nil) }

        let_it_be(:rule_schedule) do
          create(:security_orchestration_policy_rule_schedule,
            security_orchestration_policy_configuration: container.security_orchestration_policy_configuration)
        end

        it 'unassigns policy project from the project', :aggregate_failures do
          expect(result).to be_success
          expect(container.security_orchestration_policy_configuration).to be_destroyed
        end

        it 'deletes rule schedules related to the project' do
          expect { result }.to change(Security::OrchestrationPolicyRuleSchedule, :count).from(1).to(0)
        end

        context 'when destroy fails' do
          before do
            allow(container.security_orchestration_policy_configuration).to receive(:delete).and_return(false)
          end

          it { is_expected.not_to be_success }

          it 'does not delete rule schedules related to the project' do
            expect { result }.not_to change(Security::OrchestrationPolicyRuleSchedule, :count)
          end
        end
      end

      context 'when policy project is not assigned to a project or namespace' do
        let(:service) { described_class.new(container: container_without_policy_project, current_user: nil) }

        it 'respond with an error', :aggregate_failures do
          expect(result).not_to be_success
          expect(result.message).to eq("Policy project doesn't exist")
        end
      end
    end

    context 'for project' do
      let_it_be(:container, reload: true) { create(:project, :with_security_orchestration_policy_configuration) }
      let_it_be(:container_without_policy_project, reload: true) { create(:project) }

      context 'with approval rules' do
        let(:service) { described_class.new(container: container, current_user: nil) }

        context 'with scan_finding rule' do
          let_it_be(:scan_finding_rule) { create(:approval_project_rule, :scan_finding, project: container) }

          it 'deletes scan finding approval rules related to the project' do
            expect { result }.to change(ApprovalProjectRule, :count).from(1).to(0)
          end
        end

        context 'with other rule' do
          let_it_be(:license_scanning_rule) { create(:approval_project_rule, :license_scanning, project: container) }

          it 'does not delete license scanning rules' do
            expect { result }.not_to change(ApprovalProjectRule, :count)
          end
        end
      end

      it_behaves_like 'unassigns policy project'
    end

    context 'for namespace' do
      let_it_be(:container, reload: true) { create(:namespace, :with_security_orchestration_policy_configuration) }
      let_it_be(:container_without_policy_project, reload: true) { create(:namespace) }

      it_behaves_like 'unassigns policy project'
    end
  end
end
