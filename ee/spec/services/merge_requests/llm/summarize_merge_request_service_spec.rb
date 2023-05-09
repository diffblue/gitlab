# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::Llm::SummarizeMergeRequestService, feature_category: :code_review_workflow do
  let_it_be(:user)          { create(:user) }
  let_it_be(:project)       { create(:project, :with_namespace_settings, :repository, :public) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }

  let_it_be(:merge_request_2) { create(:merge_request) }
  let_it_be(:project_2)       { merge_request_2.project }

  let_it_be(:example_answer) { "This merge request includes changes to limit the transfer..." }
  let_it_be(:example_response) do
    {
      "id" => "chatcmpl-72mX77BBH9Hgj196u7BDhKyCTiXxL",
      "object" => "chat.completion",
      "created" => 1680897573,
      "model" => "gpt-3.5-turbo-0301",
      "usage" => { "prompt_tokens" => 3447, "completion_tokens" => 57, "total_tokens" => 3504 },
      "choices" =>
        [{
          "message" => { "role" => "assistant", "content" => example_answer },
          "finish_reason" => "stop",
          "index" => 0
        }]
    }
  end

  let(:response_double) { instance_double(HTTParty::Response, parsed_response: example_response) }
  let(:errored_response_double) { instance_double(HTTParty::Response, parsed_response: { error: "true" }) }

  subject(:service) { described_class.new(merge_request: merge_request, user: user) }

  describe "#execute" do
    before do
      project.add_developer(user)

      merge_request.project.namespace.namespace_settings.update_attribute(:experiment_features_enabled, true)
      merge_request.project.namespace.namespace_settings.update_attribute(:third_party_ai_features_enabled, true)
    end

    context "when the user does not have read access to the MR" do
      it "returns without attempting to summarize" do
        secondary_service = described_class.new(merge_request: merge_request_2, user: user)

        expect(secondary_service).not_to receive(:llm_client)
        expect(secondary_service.execute).to be_nil
      end
    end

    context "when the feature is not enabled" do
      context 'when the openai_experimentation flag is false' do
        before do
          stub_feature_flags(openai_experimentation: false)
        end

        it "returns without attempting to summarize" do
          expect(service).not_to receive(:llm_client)

          service.execute
        end
      end

      context 'when the project experiment_features_allowed is false' do
        before do
          merge_request.project.namespace.namespace_settings.update_attribute(:experiment_features_enabled, false)
        end

        it "returns without attempting to summarize" do
          expect(service).not_to receive(:llm_client)

          service.execute
        end
      end

      context 'when the project third_party_ai_features_enabled is false' do
        before do
          merge_request.project.namespace.namespace_settings.update_attribute(:third_party_ai_features_enabled, false)
        end

        it "returns without attempting to summarize" do
          expect(service).not_to receive(:llm_client)

          service.execute
        end
      end
    end

    context "when #llm_client is falsey" do
      before do
        allow(service).to receive(:llm_client).and_return(nil)
      end

      it "returns without attempting to summarize" do
        expect(service.execute).to be_nil
      end
    end

    context "when #llm_client.chat returns a typical response" do
      before do
        allow_next_instance_of(Gitlab::Llm::OpenAi::Client) do |llm_client|
          allow(llm_client).to receive(:chat).and_return(response_double)
        end
      end

      it "returns the content field from the OpenAI response" do
        expect(service.execute).to eq(example_answer)
      end
    end

    context "when #llm_client.chat returns an unsuccessful response" do
      before do
        allow_next_instance_of(Gitlab::Llm::OpenAi::Client) do |llm_client|
          allow(llm_client).to receive(:chat).and_return(errored_response_double)
        end
      end

      it "returns nil" do
        expect(service.execute).to be_nil
      end
    end

    context "when #llm_client.chat returns an nil response" do
      before do
        allow_next_instance_of(Gitlab::Llm::OpenAi::Client) do |llm_client|
          allow(llm_client).to receive(:chat).and_return(nil)
        end
      end

      it "returns nil" do
        expect(service.execute).to be_nil
      end
    end

    context "when #llm_client.chat returns a response without parsed_response" do
      before do
        allow_next_instance_of(Gitlab::Llm::OpenAi::Client) do |llm_client|
          allow(llm_client).to receive(:chat).and_return({ message: "Foo" })
        end
      end

      it "returns nil" do
        expect(service.execute).to be_nil
      end
    end
  end
end
