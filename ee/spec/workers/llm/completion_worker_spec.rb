# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Llm::CompletionWorker, feature_category: :team_planning do
  include AfterNextHelpers

  it_behaves_like 'worker with data consistency', described_class, data_consistency: :delayed

  describe '#perform' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group, :public) }
    let_it_be(:project) { create(:project, :public, group: group) }
    let_it_be(:resource) { create(:issue, project: project) }

    let(:user_id) { user.id }
    let(:resource_id) { resource.id }
    let(:resource_type) { resource.class.name }
    let(:options) { { 'key' => 'value' } }
    let(:ai_template) { { method: :completions, prompt: 'something', options: { temperature: 0.7 } } }
    let(:ai_action_name) { :summarize_comments }
    let(:params) { options.merge(request_id: 'uuid') }

    subject { described_class.new.perform(user_id, resource_id, resource_type, ai_action_name, params) }

    shared_examples 'performs successfully' do
      it 'calls Gitlab::Llm::CompletionsFactory' do
        completion = instance_double(Gitlab::Llm::OpenAi::Completions::SummarizeAllOpenNotes)

        expect(Gitlab::Llm::CompletionsFactory)
          .to receive(:completion)
          .with(ai_action_name, { request_id: 'uuid' })
          .and_return(completion)

        expect(completion)
          .to receive(:execute)
          .with(user, resource, options.symbolize_keys)

        subject
      end
    end

    context 'with valid parameters' do
      context 'for an issue' do
        let_it_be(:resource) { create(:issue, project: project) }

        it_behaves_like 'performs successfully'
      end

      context 'for a work item' do
        let_it_be(:resource) { create(:work_item, :task, project: project) }

        it_behaves_like 'performs successfully'
      end

      context 'for a merge request' do
        let_it_be(:resource) { create(:merge_request, source_project: project) }

        it_behaves_like 'performs successfully'
      end

      context 'for an epic' do
        let_it_be(:resource) { create(:epic) }

        before do
          stub_licensed_features(epics: true)
        end

        it_behaves_like 'performs successfully'
      end
    end

    context 'with invalid parameters' do
      context 'when issue type is not supported' do
        let(:resource_type) { 'invalid' }

        it 'raises a NameError' do
          expect { subject }.to raise_error(NameError, "uninitialized constant Invalid")
        end
      end

      context 'when issue is confidential' do
        let_it_be(:resource) { create(:issue, :confidential, project: project) }

        it 'does not call Gitlab::Llm::CompletionsFactory.completion' do
          expect(Gitlab::Llm::CompletionsFactory).not_to receive(:completion)

          subject
        end

        it { is_expected.to be_nil }

        context 'when user can read resource' do
          let(:user) { resource.project.owner }

          it 'does not call Gitlab::Llm::CompletionsFactory.completion' do
            expect(Gitlab::Llm::CompletionsFactory).not_to receive(:completion)

            subject
          end
        end
      end

      context 'when project is not public' do
        let_it_be(:project) { create(:project, :private) }
        let_it_be(:resource) { create(:issue, project: project) }

        it 'does not call Gitlab::Llm::CompletionsFactory.completion' do
          expect(Gitlab::Llm::CompletionsFactory).not_to receive(:completion)

          subject
        end

        it { is_expected.to be_nil }

        context 'when user can read resource' do
          let(:user) { project.owner }

          it 'does not call Gitlab::Llm::CompletionsFactory.completion' do
            expect(Gitlab::Llm::CompletionsFactory).not_to receive(:completion)

            subject
          end
        end
      end
    end
  end
end
