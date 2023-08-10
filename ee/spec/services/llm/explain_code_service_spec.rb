# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Llm::ExplainCodeService, :saas, feature_category: :source_code_management do
  let_it_be_with_reload(:group) { create(:group_with_plan, plan: :ultimate_plan) }
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, group: group) }

  let(:options) do
    {
      messages: [
        { role: 'system', content: 'system content' },
        { role: 'user', content: 'user content' }
      ]
    }
  end

  let(:experiment_features_enabled) { true }
  let(:third_party_features_enabled) { true }

  subject { described_class.new(user, project, options) }

  before do
    stub_application_setting(check_namespace_plan: true)
    stub_licensed_features(explain_code: true, ai_features: true)
    group.update!(experiment_features_enabled: experiment_features_enabled,
      third_party_ai_features_enabled: third_party_features_enabled)
  end

  describe '#perform' do
    context 'when is a member of the group' do
      before do
        group.add_developer(user)
      end

      context 'when feature flag is enabled' do
        let(:resource) { project }
        let(:action_name) { :explain_code }
        let(:content) { 'Explain code' }

        it_behaves_like 'service not emitting message for user prompt'
        it_behaves_like 'completion worker sync and async'
        it_behaves_like 'llm service does not cache user request'
      end

      context 'when explain_code_vertex_ai feature flag is disabled' do
        before do
          stub_feature_flags(explain_code_vertex_ai: false)
        end

        let(:resource) { project }
        let(:action_name) { :explain_code_open_ai }
        let(:content) { 'Explain code' }

        it_behaves_like 'service not emitting message for user prompt'
        it_behaves_like 'completion worker sync and async'
        it_behaves_like 'llm service does not cache user request'
      end

      context 'when explain_code_snippet feature flag is disabled' do
        before do
          stub_feature_flags(explain_code_snippet: false)
        end

        it 'returns an error' do
          expect(Llm::CompletionWorker).not_to receive(:perform_async)

          expect(subject.execute).to be_error
        end
      end

      context 'when explain_code licensed feature is disabled' do
        before do
          stub_licensed_features(explain_code: false)
        end

        it 'returns an error' do
          expect(Llm::CompletionWorker).not_to receive(:perform_async)

          expect(subject.execute).to be_error
        end
      end

      it 'returns an error when messages are too big' do
        stub_const("#{described_class}::INPUT_CONTENT_LIMIT", 4)

        expect(Llm::CompletionWorker).not_to receive(:perform_async)

        expect(subject.execute).to be_error.and have_attributes(message: eq('The messages are too big'))
      end

      context 'when experimental features are not enabled' do
        let(:experiment_features_enabled) { false }

        it 'returns an error' do
          expect(Llm::CompletionWorker).not_to receive(:perform_async)

          expect(subject.execute).to be_error
        end
      end

      context 'when third-party features are not enabled' do
        let(:third_party_features_enabled) { false }

        it 'returns an error' do
          expect(Llm::CompletionWorker).not_to receive(:perform_async)

          expect(subject.execute).to be_error
        end
      end
    end

    context 'when is not a member' do
      it 'returns an error if user is not a member of the project' do
        expect(Llm::CompletionWorker).not_to receive(:perform_async)

        expect(subject.execute).to be_error
      end
    end
  end
end
