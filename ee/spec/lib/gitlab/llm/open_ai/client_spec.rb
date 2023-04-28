# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::OpenAi::Client, feature_category: :not_owned do # rubocop: disable  RSpec/InvalidFeatureCategory
  let_it_be(:user) { create(:user) }

  let(:access_token) { 'secret' }
  let(:default_options) { {} }
  let(:expected_options) { {} }
  let(:options) { {} }
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

  let(:response_double) do
    instance_double(HTTParty::Response, code: 200, success?: true, parsed_response: example_response)
  end

  before do
    allow(response_double).to receive(:server_error?).and_return(false)
    allow(response_double).to receive(:too_many_requests?).and_return(false)
    allow_next_instance_of(::OpenAI::Client) do |open_ai_client|
      allow(open_ai_client)
        .to receive(:public_send)
        .with(method, hash_including(expected_options))
        .and_return(response_double)
    end
  end

  shared_examples 'forwarding the request correctly' do
    before do
      stub_application_setting(openai_api_key: access_token)
    end

    context 'when feature flag and access token is set' do
      it { is_expected.to eq(response_double) }

      describe 'cost tracking' do
        it 'tracks prompt and completion tokens cost' do
          counter = instance_double(Prometheus::Client::Counter, increment: true)

          allow(Gitlab::Metrics)
            .to receive(:counter)
            .with(:gitlab_cloud_cost_spend_entry_total, anything)
            .and_return(counter)

          expect(counter)
            .to receive(:increment)
            .with(
              { vendor: 'open_ai', item: 'model/prompt', unit: 'tokens' },
              example_response['usage']['prompt_tokens']
            )

          expect(counter)
            .to receive(:increment)
            .with(
              { vendor: 'open_ai', item: 'model/completion', unit: 'tokens' },
              example_response['usage']['completion_tokens']
            )

          subject
        end
      end
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

  describe '#chat' do
    subject(:chat) { described_class.new(user).chat(content: 'anything', **options) }

    let(:method) { :chat }

    it_behaves_like 'forwarding the request correctly'
  end

  describe '#messages_chat' do
    stub_feature_flags(openai_experimentation: true)

    subject(:messages_chat) do
      described_class.new(user).messages_chat(
        messages: messages,
        **options
      )
    end

    let(:messages) do
      [
        { role: described_class::SYSTEM_ROLE, content: 'you are a language model' },
        { role: described_class::DEFAULT_ROLE, content: 'what?' }
      ]
    end

    let(:method) { :chat }
    let(:options) { { temperature: 0.1 } }
    let(:expected_options) { { parameters: hash_including({ messages: messages, temperature: 0.1 }) } }

    it_behaves_like 'forwarding the request correctly'

    context 'without the correct role' do
      before do
        stub_application_setting(openai_api_key: access_token)
      end

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
    subject(:completions) { described_class.new(user).completions(prompt: 'anything', **options) }

    let(:method) { :completions }

    it_behaves_like 'forwarding the request correctly'
  end

  describe '#edits' do
    subject(:edits) { described_class.new(user).edits(input: 'foo', instruction: 'bar', **options) }

    let(:method) { :edits }

    it_behaves_like 'forwarding the request correctly'
  end

  describe '#embeddings' do
    subject(:embeddings) { described_class.new(user).embeddings(input: 'foo', **options) }

    let(:method) { :embeddings }
    let(:example_response) do
      {
        'model' => 'model',
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
  end
end
