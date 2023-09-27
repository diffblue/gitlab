# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Llm::CompletionWorker, feature_category: :ai_abstraction_layer do
  include FakeBlobHelpers
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
    let(:referer_url) { nil }
    let(:extra_resource) { {} }
    let(:completion) { instance_double(Gitlab::Llm::Completions::SummarizeAllOpenNotes) }

    let(:params) do
      options.merge(request_id: 'uuid', internal_request: true, cache_response: false, referer_url: referer_url)
    end

    subject { described_class.new.perform(user_id, resource_id, resource_type, ai_action_name, params) }

    shared_examples 'performs successfully' do
      it 'calls Gitlab::Llm::CompletionsFactory and tracks event', :aggregate_failures do
        completion = instance_double(Gitlab::Llm::Completions::SummarizeAllOpenNotes)
        response_double = instance_double(Gitlab::Llm::BaseResponseModifier)
        extra_resource_finder = instance_double(::Llm::ExtraResourceFinder)

        expect(::Llm::ExtraResourceFinder).to receive(:new).with(user, referer_url).and_return(extra_resource_finder)
        expect(extra_resource_finder).to receive(:execute).and_return(extra_resource)

        expect(Gitlab::Llm::CompletionsFactory)
          .to receive(:completion)
          .with(ai_action_name, match({ internal_request: true, request_id: 'uuid', cache_response: false }))
          .and_return(completion)

        expect(completion)
          .to receive(:execute)
          .with(user, resource, options.symbolize_keys.merge(extra_resource: extra_resource))
          .and_return(response_double)

        expect(subject).to eq(response_double)

        expect_snowplow_event(
          category: described_class.to_s,
          action: 'perform_completion_worker',
          label: ai_action_name.to_s,
          property: 'uuid',
          user: user
        )
      end
    end

    context 'with valid parameters' do
      before do
        group.add_reporter(user)
      end

      it 'updates duration metric' do
        allow(Gitlab::Llm::CompletionsFactory)
          .to receive(:completion)
          .and_return(completion)
        allow(completion).to receive(:execute)

        expect(Gitlab::Metrics::Sli::Apdex[:llm_completion])
          .to receive(:increment)
          .with(labels: { feature_category: anything, service_class: an_instance_of(String) }, success: true)

        subject
      end

      context 'when extra resource is found' do
        let(:referer_url) { "foobar" }
        let(:extra_resource) { { blob: fake_blob(path: 'file.md') } }

        it_behaves_like 'performs successfully'
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

        it 'raises a NameError and updates error rate' do
          expect(Gitlab::Metrics::Sli::ErrorRate[:llm_completion])
            .to receive(:increment)
            .with(labels: {
              feature_category: :ai_abstraction_layer,
              service_class: 'Gitlab::Llm::Completions::SummarizeAllOpenNotes'
            }, error: true)

          expect { subject }.to raise_error(NameError, 'uninitialized constant Invalid')
        end
      end

      context 'when invalid action_name is used' do
        let(:ai_action_name) { :some_action }

        it 'raises an exception' do
          expect { subject }.to raise_error(NameError, 'completion class for action some_action not found')
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
