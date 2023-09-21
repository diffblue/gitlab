# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Completions::Chat, feature_category: :duo_chat do
  include FakeBlobHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :repository,  group: group) }
  let_it_be(:issue) { create(:issue, project: project) }

  let(:resource) { issue }
  let(:expected_container) { group }
  let(:content) { 'Summarize issue' }
  let(:ai_request) { instance_double(Gitlab::Llm::Chain::Requests::Anthropic) }
  let(:blob) { fake_blob(path: 'file.md') }
  let(:extra_resource) { { blob: blob } }
  let(:options) { { request_id: 'uuid', content: content, extra_resource: extra_resource } }
  let(:params) { { request_id: 'uuid' } }
  let(:container) { group }
  let(:context) do
    instance_double(
      Gitlab::Llm::Chain::GitlabContext,
      tools_used: [::Gitlab::Llm::Chain::Tools::IssueIdentifier::Executor],
      container: container,
      current_user: user,
      resource: resource
    )
  end

  let(:answer) do
    ::Gitlab::Llm::Chain::Answer.new(
      status: :ok, context: context, content: content, tool: nil, is_final: true
    )
  end

  let(:response_handler) { instance_double(Gitlab::Llm::ResponseService) }
  let(:chat_response_handler) { instance_double(Gitlab::Llm::ChatResponseService) }
  let(:stream_response_handler) { nil }

  subject { described_class.new(nil, **params).execute(user, resource, options) }

  shared_examples 'success' do
    it 'calls the ZeroShot Agent with the right parameters', :snowplow do
      tools = [
        ::Gitlab::Llm::Chain::Tools::IssueIdentifier,
        ::Gitlab::Llm::Chain::Tools::JsonReader,
        ::Gitlab::Llm::Chain::Tools::GitlabDocumentation,
        ::Gitlab::Llm::Chain::Tools::EpicIdentifier,
        ::Gitlab::Llm::Chain::Tools::CiEditorAssistant
      ]

      expected_params = [
        user_input: content,
        tools: match_array(tools),
        context: context,
        response_handler: response_handler,
        stream_response_handler: stream_response_handler
      ]

      expect_next_instance_of(::Gitlab::Llm::Chain::Agents::ZeroShot::Executor, *expected_params) do |instance|
        expect(instance).to receive(:execute).and_return(answer)
      end

      expect(response_handler).to receive(:execute)
      expect(::Gitlab::Llm::ResponseService).to receive(:new).with(context, { request_id: 'uuid' })
        .and_return(response_handler)
      expect(chat_response_handler).to receive(:execute)
      expect(::Gitlab::Llm::ChatResponseService).to receive(:new).with(context, { request_id: 'uuid' })
        .and_return(chat_response_handler)
      expect(::Gitlab::Llm::Chain::GitlabContext).to receive(:new)
        .with(current_user: user, container: expected_container, resource: resource, ai_request: ai_request,
          extra_resource: extra_resource)
        .and_return(context)

      subject

      expect_snowplow_event(
        category: described_class.to_s,
        label: "IssueIdentifier",
        action: 'process_gitlab_duo_question',
        property: 'uuid',
        namespace: container,
        user: user,
        value: 1
      )
    end

    context 'when client_subscription_id is set' do
      let(:params) { { request_id: 'uuid', content: content, client_subscription_id: 'someid' } }
      let(:stream_response_handler) { instance_double(Gitlab::Llm::ResponseService) }

      it 'correctly initialzes response handlers' do
        expected_params = [
          user_input: content,
          tools: an_instance_of(Array),
          context: an_instance_of(Gitlab::Llm::Chain::GitlabContext),
          response_handler: response_handler,
          stream_response_handler: stream_response_handler
        ]

        expect_next_instance_of(::Gitlab::Llm::Chain::Agents::ZeroShot::Executor, *expected_params) do |instance|
          expect(instance).to receive(:execute).and_return(answer)
        end

        expect(response_handler).to receive(:execute)
        expect(::Gitlab::Llm::ResponseService).to receive(:new).with(
          an_instance_of(Gitlab::Llm::Chain::GitlabContext), { request_id: 'uuid' }
        ).and_return(response_handler)

        expect(chat_response_handler).to receive(:execute)
        expect(::Gitlab::Llm::ChatResponseService).to receive(:new).with(
          an_instance_of(Gitlab::Llm::Chain::GitlabContext), { request_id: 'uuid', client_subscription_id: 'someid' }
        ).and_return(chat_response_handler)

        expect(::Gitlab::Llm::ResponseService).to receive(:new).with(
          an_instance_of(Gitlab::Llm::Chain::GitlabContext), { request_id: 'uuid', client_subscription_id: 'someid' }
        ).and_return(stream_response_handler)

        subject
      end
    end

    context 'with unsuccessful response' do
      let(:answer) do
        ::Gitlab::Llm::Chain::Answer.new(
          status: :error, context: context, content: content, tool: nil, is_final: true
        )
      end

      it 'sends process_gitlab_duo_question snowplow event with value eql 0' do
        allow_next_instance_of(::Gitlab::Llm::Chain::Agents::ZeroShot::Executor) do |instance|
          expect(instance).to receive(:execute).and_return(answer)
        end

        allow(::Gitlab::Llm::Chain::GitlabContext).to receive(:new).and_return(context)

        subject

        expect_snowplow_event(
          category: described_class.to_s,
          label: "IssueIdentifier",
          action: 'process_gitlab_duo_question',
          property: 'uuid',
          namespace: container,
          user: user,
          value: 0
        )
      end
    end
  end

  describe '#execute' do
    before do
      allow(Gitlab::Llm::Chain::Requests::Anthropic).to receive(:new).and_return(ai_request)
    end

    context 'when resource is an issue' do
      it_behaves_like 'success'
    end

    context 'when resource is a user' do
      let(:container) { nil }
      let(:expected_container) { nil }
      let_it_be(:resource) { user }

      it_behaves_like 'success'
    end

    context 'when resource is nil' do
      let(:resource) { nil }
      let(:expected_container) { nil }

      it_behaves_like 'success'
    end

    context 'when ci_editor_assistant_tool flag is switched off' do
      before do
        stub_feature_flags(ci_editor_assistant_tool: false)
      end

      it 'calls zero shot agent with tools without Ci Editor Assistant' do
        tools = [
          ::Gitlab::Llm::Chain::Tools::JsonReader,
          ::Gitlab::Llm::Chain::Tools::IssueIdentifier,
          ::Gitlab::Llm::Chain::Tools::GitlabDocumentation,
          ::Gitlab::Llm::Chain::Tools::EpicIdentifier
        ]
        expected_params = [
          user_input: content,
          tools: match_array(tools),
          context: context,
          response_handler: response_handler,
          stream_response_handler: stream_response_handler
        ]

        expect_next_instance_of(::Gitlab::Llm::Chain::Agents::ZeroShot::Executor, *expected_params) do |instance|
          expect(instance).to receive(:execute).and_return(answer)
        end
        expect(response_handler).to receive(:execute)
        expect(::Gitlab::Llm::ResponseService).to receive(:new).with(context, { request_id: 'uuid' })
          .and_return(response_handler)
        expect(chat_response_handler).to receive(:execute)
        expect(::Gitlab::Llm::ChatResponseService).to receive(:new).with(context, { request_id: 'uuid' })
          .and_return(chat_response_handler)
        expect(::Gitlab::Llm::Chain::GitlabContext).to receive(:new)
          .with(current_user: user, container: expected_container, resource: resource,
            ai_request: ai_request, extra_resource: extra_resource)
          .and_return(context)

        subject
      end
    end
  end
end
