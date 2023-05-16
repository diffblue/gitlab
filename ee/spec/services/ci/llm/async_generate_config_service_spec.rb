# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Llm::AsyncGenerateConfigService, feature_category: :pipeline_composition do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let(:user_content) { 'my content' }

  let(:service_instance) { described_class.new(project: project, user: user, user_content: user_content) }

  describe '#execute' do
    subject { service_instance.execute }

    before do
      stub_licensed_features(ai_config_chat: true)
    end

    shared_examples 'error' do |reason, message|
      it 'returns a service error' do
        expect(subject.reason).to eq reason
        expect(subject.message).to eq message
        expect(subject.error?).to eq true
      end
    end

    context 'when the user is not a project member' do
      it_behaves_like 'error', :not_found, 'Not Found'
    end

    context "when the user is a project member who can't push code" do
      before do
        project.add_reporter(user)
      end

      it_behaves_like 'error', :not_found, 'Not Found'
    end

    context "when the user is a project member who can push code" do
      before do
        project.add_developer(user)
      end

      context 'when the user content is too large' do
        let(:user_content) { 'a' * (described_class::INPUT_CHAR_LIMIT + 10) }

        it_behaves_like 'error', :content_size, 'User content is too large'
      end

      context 'when the feature is not avalible' do
        shared_examples 'feature not avalible' do
          it_behaves_like 'error', :not_found, 'Feature not available'
        end

        context 'when ai_ci_config_generator is off' do
          before do
            stub_feature_flags(ai_ci_config_generator: false)
          end

          it_behaves_like 'feature not avalible'
        end

        context 'when openai_experimentation is off' do
          before do
            stub_feature_flags(openai_experimentation: false)
          end

          it_behaves_like 'feature not avalible'
        end

        context 'when unlicensed' do
          before do
            stub_licensed_features(ai_config_chat: false)
          end

          it_behaves_like 'feature not avalible'
        end
      end

      context 'when the token is present' do
        let(:ai_messages) { Ci::Editor::AiConversation::Message.where(role: Gitlab::Llm::OpenAi::Options::AI_ROLE) }
        let(:user_messages) do
          Ci::Editor::AiConversation::Message.where(role: Gitlab::Llm::OpenAi::Options::DEFAULT_ROLE)
        end

        before do
          allow_next_instance_of(Gitlab::Llm::OpenAi::Client) do |client|
            allow(client).to receive(:token_present?).and_return(true)
          end
        end

        it 'persists an ai message and user message' do
          expect { subject }.to change { Ci::Editor::AiConversation::Message.all.reload.count }.by(2)
            .and change { ai_messages.reload.count }.by(1)
            .and change { user_messages.reload.count }.by(1)

          expect(user_messages.last.content).to eq user_content
          expect(ai_messages.last.async_errors).to be_empty

          expect(ai_messages.last.content).to be_nil
          expect(ai_messages.last.async_errors).to be_empty
        end

        it 'starts an async worker' do
          ai_message = instance_double(Ci::Editor::AiConversation::Message, id: 1)
          allow(Ci::Editor::AiConversation::Message).to receive(:create).and_call_original
          allow(Ci::Editor::AiConversation::Message).to receive(:create).and_return(ai_message)
          expect(Ci::Llm::GenerateConfigWorker).to receive(:perform_async).with(ai_message.id)

          subject
        end
      end
    end
  end
end
