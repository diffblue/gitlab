# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'scan policies finder' do
  subject { described_class.new(actor, object, params).execute }

  describe '#execute' do
    context 'when execute is not implemented in the subclass' do
      let(:example_class) do
        Class.new(Security::ScanPolicyBaseFinder) do
          def initialize(actor, project, params)
            super(actor, project, :new_finder, params)
          end
        end
      end

      it 'raises NotImplementedError' do
        expect { example_class.new(actor, object, params).execute }.to raise_error NotImplementedError
      end
    end

    context 'when feature is not licensed' do
      before do
        stub_licensed_features(security_orchestration_policies: false)
      end

      it 'returns empty collection' do
        is_expected.to be_empty
      end
    end

    context 'when feature is licensed' do
      before do
        stub_licensed_features(security_orchestration_policies: true)
      end

      context 'when configuration is associated to project' do
        it 'returns policies with project' do
          is_expected.to match_array([policy.merge(
            {
              config: policy_configuration,
              project: object,
              namespace: nil,
              inherited: false
            })])
        end
      end

      context 'when configuration is associated to namespace' do
        let!(:policy_configuration) { nil }

        let!(:group_policy_configuration) do
          create(
            :security_orchestration_policy_configuration,
            :namespace,
            security_policy_management_project: policy_management_project,
            namespace: group
          )
        end

        context 'when relationship argument is not provided' do
          it 'returns no policies' do
            is_expected.to be_empty
          end
        end

        context 'when relationship argument is provided as INHERITED' do
          let(:relationship) { :inherited }

          it 'returns scan policies for groups only' do
            is_expected.to match_array([policy.merge(
              {
                config: group_policy_configuration,
                project: nil,
                namespace: group,
                inherited: true
              })])
          end
        end
      end

      context 'when configuration is associated to project and namespace' do
        let!(:group_policy_configuration) do
          create(
            :security_orchestration_policy_configuration,
            :namespace,
            security_policy_management_project: policy_management_project,
            namespace: group
          )
        end

        context 'when relationship argument is not provided' do
          it 'returns scan policies for project only' do
            is_expected.to match_array([policy.merge(
              {
                config: policy_configuration,
                project: object,
                namespace: nil,
                inherited: false
              })])
          end
        end

        context 'when relationship argument is provided as INHERITED' do
          let(:relationship) { :inherited }

          it 'returns policies defined for both project and namespace' do
            is_expected.to match_array(
              [
                policy.merge(
                  {
                    config: policy_configuration,
                    project: object,
                    namespace: nil,
                    inherited: false
                  }),
                policy.merge(
                  {
                    config: group_policy_configuration,
                    project: nil,
                    namespace: group,
                    inherited: true
                  })
              ])
          end
        end

        context 'when relationship argument is provided as INHERITED_ONLY' do
          let(:relationship) { :inherited_only }

          it 'returns policies defined for namespace only' do
            is_expected.to match_array([policy.merge(
              {
                config: group_policy_configuration,
                project: nil,
                namespace: group,
                inherited: true
              })])
          end
        end
      end

      context 'when user is unauthorized' do
        let(:actor) { create(:user) }

        it 'returns empty collection' do
          is_expected.to be_empty
        end
      end
    end
  end
end
