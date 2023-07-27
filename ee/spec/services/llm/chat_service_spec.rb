# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Llm::ChatService, :saas, feature_category: :shared do
  let_it_be_with_reload(:group) { create(:group_with_plan, plan: :ultimate_plan) }
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:issue) { create(:issue, project: project) }

  let(:resource) { issue }
  let(:stage_check_available) { true }
  let(:content) { "Summarize issue" }
  let(:options) { { content: content, skip_cache: false } }

  subject { described_class.new(user, resource, options) }

  before do
    stub_feature_flags(gitlab_duo: user)
  end

  describe '#perform' do
    context 'when ai features are enabled for the group' do
      include_context 'with ai features enabled for group'

      before do
        stub_feature_flags(gitlab_duo: user)
        allow(Gitlab::Llm::StageCheck).to receive(:available?).with(group, :chat).and_return(stage_check_available)
      end

      context 'when user is part of the group' do
        before do
          group.add_developer(user)
        end

        context 'when resource is an issue' do
          it_behaves_like 'completion worker sync and async' do
            let(:resource) { issue }
            let(:action_name) { :chat }
            let(:content) { 'Summarize issue' }
          end
        end

        context 'when resource is a user' do
          it_behaves_like 'completion worker sync and async' do
            let(:resource) { user }
            let(:action_name) { :chat }
            let(:content) { 'How to reset the password' }
          end
        end

        context 'when gitlab_duo feature flag is disabled' do
          before do
            stub_feature_flags(gitlab_duo: false)
          end

          it 'returns an error' do
            expect(Llm::CompletionWorker).not_to receive(:perform_async)

            expect(subject.execute).to be_error
          end
        end
      end

      context 'when user is not part of the group' do
        it 'returns an error' do
          expect(Llm::CompletionWorker).not_to receive(:perform_async)
          expect(subject.execute).to be_error
        end
      end
    end
  end
end
