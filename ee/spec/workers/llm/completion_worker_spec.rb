# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Llm::CompletionWorker, feature_category: :team_planning do
  include AfterNextHelpers

  it_behaves_like 'worker with data consistency', described_class, data_consistency: :delayed

  describe '#perform' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, group: group) }
    let_it_be(:resource) { create(:issue, project: project) }

    let(:user_id) { user.id }
    let(:resource_id) { resource.id }
    let(:resource_type) { resource.class.name }
    let(:options) { { 'key' => 'value' } }
    let(:ai_template) { { method: :completions, prompt: 'something', options: { temperature: 0.7 } } }
    let(:ai_action_name) { :summarize_comments }
    let(:params) { options.merge(request_id: 'uuid', internal_request: true, skip_cache: true) }

    subject { described_class.new.perform(user_id, resource_id, resource_type, ai_action_name, params) }

    shared_examples 'performs successfully' do
      it 'calls Gitlab::Llm::CompletionsFactory' do
        completion = instance_double(Gitlab::Llm::Completions::SummarizeAllOpenNotes)

        expect(Gitlab::Llm::CompletionsFactory)
          .to receive(:completion)
          .with(ai_action_name, match({ internal_request: true, request_id: 'uuid', skip_cache: true }))
          .and_return(completion)

        expect(completion)
          .to receive(:execute)
          .with(user, resource, options.symbolize_keys)

        subject
      end
    end

    context 'with valid parameters' do
      before do
        group.add_reporter(user)
      end

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

      context 'when resource is nil' do
        let(:resource) { nil }
        let(:resource_id) { nil }
        let(:resource_type) { nil }
        let(:ai_action_name) { :chat }

        it_behaves_like 'performs successfully'
      end
    end

    context 'with invalid parameters' do
      before do
        group.add_guest(user)
      end

      context 'when issue type is not supported' do
        let(:resource_type) { 'invalid' }

        it 'raises a NameError' do
          expect { subject }.to raise_error(NameError, "uninitialized constant Invalid")
        end
      end
    end

    context 'when user can not read the resource' do
      it 'does not call Gitlab::Llm::CompletionsFactory.completion' do
        expect(Gitlab::Llm::CompletionsFactory).not_to receive(:completion)

        subject
      end
    end
  end
end
