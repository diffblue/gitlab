# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::OpenAiChatResponse, feature_category: :continuous_integration do
  let(:example_response_content) { '    response content   ' }

  let(:successful_raw_response) do
    {
      "id" => "chatcmpl-72mX77BBH9Hgj196u7BDhKyCTiXxL",
      "object" => "chat.completion",
      "created" => 1680897573,
      "model" => "gpt-3.5-turbo-0301",
      "usage" => { "prompt_tokens" => 3447, "completion_tokens" => 57, "total_tokens" => 3504 },
      "choices" =>
      [{
        "message" => { "role" => "assistant", "content" => example_response_content },
        "finish_reason" => "stop",
        "index" => 0
      }]
    }.to_json
  end

  let(:error_code) { "content_length_exceeded" }
  let(:error_message) { "some error message" }

  let(:failed_raw_response) do
    {
      "error" => {
        "code" => error_code,
        "message" => error_message
      }
    }.to_json
  end

  let(:response) { described_class.new(raw_json_response) }

  describe '#content' do
    subject { response.content }

    context 'when successful' do
      let(:raw_json_response) { successful_raw_response }

      it 'returns the message content' do
        expect(response.content).to eq example_response_content
      end
    end

    context 'when error' do
      let(:raw_json_response) { failed_raw_response }

      it 'returns the message content' do
        expect(response.content).to be_nil
      end
    end
  end

  describe '#error_code' do
    subject { response.error_code }

    context 'when successful' do
      let(:raw_json_response) { successful_raw_response }

      it 'returns the message content' do
        expect(response.error_code).to be_nil
      end
    end

    context 'when error' do
      let(:raw_json_response) { failed_raw_response }

      it 'returns the message content' do
        expect(response.error_code).to eq error_code
      end
    end
  end

  describe '#error_message' do
    subject { response.error_message }

    context 'when successful' do
      let(:raw_json_response) { successful_raw_response }

      it 'returns the message content' do
        expect(response.error_message).to be_nil
      end
    end

    context 'when error' do
      let(:raw_json_response) { failed_raw_response }

      it 'returns the message content' do
        expect(response.error_message).to eq error_message
      end
    end
  end

  describe '#finish_reason' do
    subject { response.finish_reason }

    context 'when successful' do
      let(:raw_json_response) { successful_raw_response }

      it 'returns the message content' do
        expect(response.finish_reason).to eq "stop"
      end
    end

    context 'when error' do
      let(:raw_json_response) { failed_raw_response }

      it 'returns the message content' do
        expect(response.finish_reason).to be_nil
      end
    end
  end
end
