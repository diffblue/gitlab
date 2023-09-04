# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::OpenAi::Client, feature_category: :ai_abstraction_layer do
  let_it_be(:user) { create(:user) }

  let(:access_token) { 'secret' }
  let(:default_options) { {} }
  let(:expected_options) { {} }
  let(:options) { {} }
  let(:response) { instance_double(Net::HTTPResponse, body: example_response.to_json) }
  let(:tracking_context) { { request_id: 'uuid', action: 'chat' } }
  let(:example_response) do
    {
      'model' => 'model',
      'choices' => [
        {
          'message' => {
            'content' => 'foo'
          }
        },
        {
          'message' => {
            'content' => 'bar'
          }
        }
      ],
      'usage' => {
        'prompt_tokens' => 1,
        'completion_tokens' => 2,
        'total_tokens' => 3
      }
    }
  end

  let(:moderation_response) do
    { 'results' => [{ 'flagged' => false }] }
  end

  let(:response_double) do
    instance_double(HTTParty::Response, code: 200, success?: true,
      response: response, parsed_response: example_response)
  end

  let(:moderation_response_double) do
    instance_double(HTTParty::Response, code: 200, success?: true,
      response: response, parsed_response: moderation_response)
  end

  around do |ex|
    # Silence moderation unset deprecations
    ActiveSupport::Deprecation.silence do
      ex.run
    end
  end

  before do
    allow(response_double).to receive(:server_error?).and_return(false)
    allow(response_double).to receive(:too_many_requests?).and_return(false)
    allow(moderation_response_double).to receive(:server_error?).and_return(false)
    allow(moderation_response_double).to receive(:too_many_requests?).and_return(false)
    allow_next_instance_of(::OpenAI::Client) do |open_ai_client|
      allow(open_ai_client)
        .to receive(:public_send)
        .with(method, hash_including(expected_options))
        .and_return(response_double)

      allow(open_ai_client)
        .to receive(:public_send)
        .with(:moderations, anything)
        .and_return(moderation_response_double)
    end

    stub_application_setting(openai_api_key: access_token)
  end

  shared_examples 'forwarding the request correctly' do
    context 'when feature flag and access token is set' do
      it { is_expected.to eq(response_double) }
    end

    context 'when using options' do
      let(:expected_options) { { parameters: hash_including({ temperature: 0.1 }) } }
      let(:options) { { temperature: 0.1 } }

      it { is_expected.to eq(response_double) }
    end

    context 'when the feature flag is disabled' do
      before do
        stub_feature_flags(openai_experimentation: false)
      end

      it { is_expected.to be_nil }
    end

    context 'when the access key is not present' do
      let(:access_token) { nil }

      it { is_expected.to be_nil }
    end
  end

  shared_examples 'cost tracking' do
    it 'tracks prompt and completion tokens cost' do
      ::Gitlab::ApplicationContext.push(feature_category: 'not_owned')

      counter = instance_double(Prometheus::Client::Counter, increment: true)

      allow(Gitlab::Metrics::Sli::ErrorRate[:llm_client_request]).to receive(:increment)
      allow(Gitlab::Metrics).to receive(:counter).and_return(counter)

      expect(counter)
        .to receive(:increment)
        .with(
          {
            vendor: 'open_ai',
            item: "#{method}/prompt",
            unit: 'tokens',
            feature_category: 'not_owned'
          },
          example_response['usage']['prompt_tokens']
        )

      expect(counter)
        .to receive(:increment)
        .with(
          {
            vendor: 'open_ai',
            item: "#{method}/completion",
            unit: 'tokens',
            feature_category: 'not_owned'
          },
          example_response['usage']['completion_tokens']
        )

      subject
    end
  end

  shared_examples 'event tracking' do
    it 'tracks a snowplow event' do
      subject

      expect_snowplow_event(
        category: described_class.to_s,
        action: 'tokens_per_user_request_prompt',
        property: 'uuid',
        label: 'chat',
        user: user,
        value: example_response['usage']['prompt_tokens']
      )

      expect_snowplow_event(
        category: described_class.to_s,
        action: 'tokens_per_user_request_response',
        property: 'uuid',
        label: 'chat',
        user: user,
        value: example_response['usage']['completion_tokens']
      )
    end
  end

  shared_examples 'input moderation' do
    context 'when moderation flag is nil' do
      let(:options) { { moderated: nil } }

      it 'produces a deprecation warning' do
        expect_next_instance_of(::OpenAI::Client) do |open_ai_client|
          expect(open_ai_client)
            .to receive(:public_send)
            .with(method, anything)
            .and_return(response_double)

          allow(open_ai_client)
            .to receive(:public_send)
            .with(:moderations, anything)
            .and_return(moderation_response_double)
        end

        expect(ActiveSupport::Deprecation).to receive(:warn).with(/`moderated` argument is not set/, anything)

        subject
      end
    end

    context 'when moderation flag is set' do
      let(:options) { { moderated: :input } }

      context 'when response is not flagged' do
        it 'returns the response from original endpoint' do
          expect_next_instance_of(::OpenAI::Client) do |open_ai_client|
            expect(open_ai_client)
              .to receive(:public_send)
              .with(method, anything)
              .and_return(response_double)

            expect(open_ai_client)
              .to receive(:public_send)
              .with(:moderations, anything)
              .once
              .and_return(moderation_response_double)
          end

          subject
        end
      end

      context 'when response is flagged' do
        let(:moderation_response) do
          { 'results' => [{ 'flagged' => true }, { 'flagged' => false }] }
        end

        it 'raises TextModerationError' do
          expect { subject }
            .to raise_error(described_class::InputModerationError, "Provided input violates OpenAI's Content Policy")
        end
      end
    end

    context 'when moderation flag is false' do
      let(:options) { { moderated: false } }

      it 'does not call the moderation endpoint' do
        expect_next_instance_of(::OpenAI::Client) do |open_ai_client|
          expect(open_ai_client)
            .to receive(:public_send)
            .with(method, anything)
            .and_return(response_double)

          expect(open_ai_client).not_to receive(:moderations)
        end

        expect(subject).to eq(response_double)
      end
    end
  end

  shared_examples 'output moderation' do
    before do
      allow_next_instance_of(::OpenAI::Client) do |open_ai_client|
        allow(open_ai_client)
          .to receive(:public_send)
          .with(method, anything)
          .and_return(response_double)

        allow(open_ai_client)
          .to receive(:public_send)
          .with(:moderations, anything)
          .and_return(moderation_response_double)
      end
    end

    context 'when moderation flag is nil' do
      let(:options) { { moderated: nil } }

      it 'produces a deprecation warning' do
        expect(ActiveSupport::Deprecation).to receive(:warn).with(/`moderated` argument is not set/, anything)

        subject
      end
    end

    context 'when output moderation flag is true' do
      let(:options) { { moderated: :output } }

      context 'when response is not flagged' do
        it 'returns the response from original endpoint' do
          expect_next_instance_of(::OpenAI::Client) do |open_ai_client|
            expect(open_ai_client)
              .to receive(:public_send)
              .with(method, anything)
              .and_return(response_double)

            expect(open_ai_client)
              .to receive(:public_send)
              .with(:moderations, anything)
              .once
              .and_return(moderation_response_double)
          end

          subject
        end
      end

      context 'when response is flagged' do
        let(:moderation_response) do
          { 'results' => [{ 'flagged' => true }, { 'flagged' => false }] }
        end

        it 'raises TextModerationError' do
          expect { subject }
            .to raise_error(described_class::OutputModerationError, "Provided output violates OpenAI's Content Policy")
        end
      end
    end

    context 'when moderation flag is false' do
      let(:options) { { moderated: false } }

      it 'does not call the moderation endpoint' do
        expect_next_instance_of(::OpenAI::Client) do |open_ai_client|
          expect(open_ai_client)
            .to receive(:public_send)
            .with(method, anything)
            .and_return(response_double)

          expect(open_ai_client).not_to receive(:moderations)
        end

        expect(subject).to eq(response_double)
      end
    end
  end

  describe '#chat' do
    subject(:chat) do
      described_class.new(user, tracking_context: tracking_context).chat(content: 'anything', **options)
    end

    let(:method) { :chat }

    it_behaves_like 'forwarding the request correctly'
    it_behaves_like 'tracks events for AI requests', 1, 2
    include_examples 'cost tracking'
    include_examples 'event tracking'
    include_examples 'input moderation'
    include_examples 'output moderation'

    context 'when measuring request success' do
      let(:client) { :open_ai }
      let(:options) { { moderated: false } }

      it_behaves_like 'measured Llm request'

      context 'when request raises an exception' do
        before do
          allow_next_instance_of(OpenAI::Client) do |open_client|
            allow(open_client).to receive(:chat).and_raise(StandardError)
          end
        end

        it_behaves_like 'measured Llm request with error', StandardError
      end

      context 'when request is retried' do
        let(:http_status) { 429 }

        before do
          stub_const("Gitlab::Llm::Concerns::ExponentialBackoff::INITIAL_DELAY", 0.0)
          allow(response_double).to receive(:too_many_requests?).and_return(true)
        end

        it_behaves_like 'measured Llm request with error', Gitlab::Llm::Concerns::ExponentialBackoff::RateLimitError
      end
    end
  end

  describe '#messages_chat' do
    stub_feature_flags(openai_experimentation: true)

    subject(:messages_chat) do
      described_class.new(user, tracking_context: tracking_context).messages_chat(
        messages: messages,
        **options
      )
    end

    let(:messages) do
      [
        { role: ::Gitlab::Llm::OpenAi::Options::SYSTEM_ROLE, content: 'you are a language model' },
        { role: ::Gitlab::Llm::OpenAi::Options::DEFAULT_ROLE, content: 'what?' },
        { 'role' => ::Gitlab::Llm::OpenAi::Options::DEFAULT_ROLE, 'content' => 'are string keys ok?' }
      ]
    end

    let(:method) { :chat }
    let(:options) { { temperature: 0.1 } }
    let(:expected_options) { { parameters: hash_including({ messages: messages, temperature: 0.1 }) } }

    it_behaves_like 'forwarding the request correctly'
    it_behaves_like 'tracks events for AI requests', 1, 2
    include_examples 'cost tracking'
    include_examples 'event tracking'
    include_examples 'input moderation'
    include_examples 'output moderation'

    context 'without the correct role' do
      let(:messages) do
        [
          { role: 'Charles Darwin', content: 'you are a language model' },
          { role: 'Teacher', content: 'what?' }
        ]
      end

      it 'raises an error' do
        expect { messages_chat }.to raise_error ArgumentError
      end
    end
  end

  describe '#completions' do
    subject(:completions) do
      described_class.new(user, tracking_context: tracking_context).completions(prompt: 'anything', **options)
    end

    let(:method) { :completions }

    it_behaves_like 'forwarding the request correctly'
    it_behaves_like 'tracks events for AI requests', 1, 2
    include_examples 'cost tracking'
    include_examples 'event tracking'
    include_examples 'input moderation'
    include_examples 'output moderation'
  end

  describe '#edits' do
    subject(:edits) do
      described_class.new(user, tracking_context: tracking_context).edits(input: 'foo', instruction: 'bar', **options)
    end

    let(:method) { :edits }

    it_behaves_like 'forwarding the request correctly'
    it_behaves_like 'tracks events for AI requests', 1, 2
    include_examples 'cost tracking'
    include_examples 'event tracking'
    include_examples 'input moderation'
    include_examples 'output moderation'
  end

  describe '#embeddings' do
    subject(:embeddings) do
      described_class.new(user, tracking_context: tracking_context).embeddings(input: 'foo', **options)
    end

    let(:method) { :embeddings }
    let(:example_response) do
      {
        'model' => 'gpt-3.5-turbo',
        "data" => [
          {
            "embedding" => [
              -0.006929283495992422,
              -0.005336422007530928
            ]
          }
        ],
        'usage' => {
          'prompt_tokens' => 1,
          'completion_tokens' => 2,
          'total_tokens' => 3
        }
      }
    end

    it_behaves_like 'forwarding the request correctly'
    it_behaves_like 'tracks events for AI requests', 1, 2
    include_examples 'cost tracking'
    include_examples 'event tracking'
    include_examples 'input moderation'
  end

  describe '#moderations' do
    subject(:moderations) do
      described_class.new(user, tracking_context: tracking_context).moderations(input: 'foo', **options)
    end

    let(:method) { :moderations }
    let(:example_response) do
      {
        'model' => 'model',
        'results' => [
          {
            "categories" => {
              "category" => false
            },
            "category_scores" => {
              "category" => 0.22714105248451233
            },
            "flagged" => false
          }
        ]
      }
    end

    before do
      allow_next_instance_of(::OpenAI::Client) do |open_ai_client|
        allow(open_ai_client)
          .to receive(:public_send)
          .with(method, hash_including(expected_options))
          .and_return(response_double)
      end
    end

    it_behaves_like 'forwarding the request correctly'
  end
end
