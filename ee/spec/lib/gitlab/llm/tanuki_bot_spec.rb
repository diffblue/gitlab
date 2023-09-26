# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::TanukiBot, feature_category: :duo_chat do
  describe '#execute' do
    let_it_be(:user) { create(:user) }
    let_it_be(:embeddings) { create_list(:tanuki_bot_mvc, 2) }
    let_it_be(:vertex_embeddings) { create_list(:vertex_gitlab_documentation, 2) }

    let(:empty_response_message) { "I'm sorry, I was not able to find any documentation to answer your question." }
    let(:question) { 'A question' }
    let(:answer) { 'The answer.' }
    let(:logger) { instance_double('Logger') }
    let(:instance) { described_class.new(current_user: user, question: question, logger: logger) }
    let(:openai_client) { ::Gitlab::Llm::OpenAi::Client.new(user) }
    let(:vertex_client) { ::Gitlab::Llm::VertexAi::Client.new(user) }
    let(:anthropic_client) { ::Gitlab::Llm::Anthropic::Client.new(user) }
    let(:embedding) { Array.new(1536, 0.5) }
    let(:vertex_embedding) { Array.new(768, 0.5) }
    let(:openai_response) { { "data" => [{ "embedding" => embedding }] } }
    let(:vertex_response) { { "predictions" => [{ "embeddings" => { "values" => vertex_embedding } }] } }
    let(:attrs) { embeddings.map(&:id).map { |x| "CNT-IDX-#{x}" }.join(", ") }
    let(:completion_response) do
      instance_double(
        HTTParty::Response, code: 200, success?: true, body: { 'completion' => "#{answer} ATTRS: #{attrs}" }.to_json
      )
    end

    let(:status_code) { 200 }
    let(:success) { true }

    subject(:execute) { instance.execute }

    describe 'enabled_for?' do
      describe 'when :openai_experimentation and tanuki_bot FF are true' do
        where(:feature_available, :ai_feature_enabled, :result) do
          [
            [false, false, false],
            [false, true, false],
            [true, false, false],
            [true, true, true]
          ]
        end

        with_them do
          before do
            allow(License).to receive(:feature_available?).and_return(feature_available)
            allow(described_class).to receive(:ai_feature_enabled?).and_return(ai_feature_enabled)
          end

          it 'returns correct result' do
            expect(described_class.enabled_for?(user: user)).to be(result)
          end
        end
      end

      describe 'when :openai_experimentation and tanuki_bot FF are not both true' do
        where(:openai_experimentation, :tanuki_bot) do
          [
            [false, false],
            [true, false],
            [false, true]
          ]
        end

        with_them do
          before do
            allow(License).to receive(:feature_available?).and_return(true)
            allow(described_class).to receive(:ai_feature_enabled?).and_return(true)

            stub_feature_flags(openai_experimentation: openai_experimentation)
            stub_feature_flags(tanuki_bot: tanuki_bot)
          end

          it 'returns false' do
            expect(described_class.enabled_for?(user: user)).to be(false)
          end
        end
      end
    end

    describe '#ai_feature_enabled?' do
      subject { described_class.ai_feature_enabled?(user) }

      context 'when not on gitlab.com' do
        it { is_expected.to be_truthy }
      end

      context 'when on gitlab.com', :saas do
        it { is_expected.to be_falsey }

        context 'when user has a group with ai feature enabled' do
          before do
            allow(user).to receive(:any_group_with_ai_available?).and_return(true)
          end

          it { is_expected.to be_truthy }
        end

        context 'when user has no group with ai feature enabled' do
          before do
            allow(user).to receive(:any_group_with_ai_available?).and_return(false)
          end

          it { is_expected.to be_falsey }
        end
      end
    end

    describe '#show_breadcrumbs_entry_point_for' do
      before do
        allow(described_class).to receive(:enabled_for?).and_return(:enabled_for_return_value)
      end

      context 'when tanuki_bot_breadcrumbs_entry_point feature flag is enabled' do
        before do
          stub_feature_flags(tanuki_bot_breadcrumbs_entry_point: true)
        end

        it 'returns enabled_for?\'s return value' do
          expect(described_class.show_breadcrumbs_entry_point_for?(user: user)).to be(:enabled_for_return_value)
        end
      end

      context 'when tanuki_bot_breadcrumbs_entry_point feature flag is disabled' do
        before do
          stub_feature_flags(tanuki_bot_breadcrumbs_entry_point: false)
        end

        it 'returns false' do
          expect(described_class.show_breadcrumbs_entry_point_for?(user: user)).to be(false)
        end
      end
    end

    describe 'execute' do
      before do
        allow(License).to receive(:feature_available?).and_return(true)
        allow(logger).to receive(:debug)
        allow(completion_response).to receive(:code).and_return(status_code)
        allow(completion_response).to receive(:success?).and_return(success)
      end

      context 'with the ai_tanuki_bot license not available' do
        before do
          allow(License).to receive(:feature_available?).with(:ai_tanuki_bot).and_return(false)
        end

        it 'returns an empty response message' do
          expect(execute.response_body).to eq(empty_response_message)
        end
      end

      context 'with the tanuki_bot license available' do
        using RSpec::Parameterized::TableSyntax

        let(:vertex_model) { ::Embedding::Vertex::GitlabDocumentation }
        let(:openai_model) { ::Embedding::TanukiBotMvc }

        let(:vertex_client_class) { ::Gitlab::Llm::VertexAi::Client }
        let(:openai_client_class) { ::Gitlab::Llm::OpenAi::Client }

        let(:vertex_args) { { content: question } }
        let(:openai_args) { { input: question, moderated: false } }

        # rubocop:disable Layout/LineLength
        where(:use_embeddings_with_vertex, :api_endpoint, :endpoint_args, :client_class, :model_class, :embeddings_client, :embedding_response) do
          true  | :text_embeddings | ref(:vertex_args) | ref(:vertex_client_class) | ref(:vertex_model) | ref(:vertex_client) | ref(:vertex_response)
          false | :embeddings      | ref(:openai_args) | ref(:openai_client_class) | ref(:openai_model) | ref(:openai_client) | ref(:openai_response)
        end
        # rubocop:enable Layout/LineLength

        with_them do
          before do
            stub_feature_flags(use_embeddings_with_vertex: use_embeddings_with_vertex)
          end

          context 'when on Gitlab.com' do
            before do
              allow(::Gitlab).to receive(:com?).and_return(true)
            end

            context 'when no user is provided' do
              let(:user) { nil }

              it 'returns an empty response message' do
                expect(execute.response_body).to eq(empty_response_message)
              end
            end

            context 'when #ai_feature_enabled is false' do
              before do
                allow(described_class).to receive(:ai_feature_enabled?).and_return(false)
              end

              it 'returns an empty response message' do
                expect(execute.response_body).to eq(empty_response_message)
              end
            end

            context 'when #ai_feature_enabled is true' do
              before do
                allow(client_class).to receive(:new).and_return(embeddings_client)
                allow(::Gitlab::Llm::Anthropic::Client).to receive(:new).and_return(anthropic_client)
                allow(described_class).to receive(:ai_feature_enabled?).and_return(true)
              end

              context 'when `tanuki_bot_mvc` table is empty (no embeddings are stored in the table)' do
                it 'returns an empty response message' do
                  model_class.connection.execute("truncate #{model_class.table_name}")

                  expect(execute.response_body).to eq(empty_response_message)
                end
              end

              it 'executes calls through to anthropic' do
                embeddings

                expect(anthropic_client).to receive(:complete).once.and_return(completion_response)
                expect(embeddings_client).to receive(api_endpoint).with(**endpoint_args).and_return(embedding_response)
                allow(completion_response).to receive(:parsed_response).and_return(completion_response)

                execute
              end
            end
          end

          context 'when the feature flags are disabled' do
            using RSpec::Parameterized::TableSyntax

            where(:openai_experimentation, :tanuki_bot) do
              true  | false
              false | true
              false | false
            end

            with_them do
              before do
                stub_feature_flags(openai_experimentation: openai_experimentation)
                stub_feature_flags(tanuki_bot: tanuki_bot)
              end

              it 'returns an empty response message' do
                expect(execute.response_body).to eq(empty_response_message)
              end
            end
          end

          context 'when the feature flags are enabled' do
            before do
              allow(completion_response).to receive(:parsed_response).and_return(completion_response)
              allow(client_class).to receive(:new).and_return(embeddings_client)
              allow(::Gitlab::Llm::Anthropic::Client).to receive(:new).and_return(anthropic_client)
              allow(user).to receive(:any_group_with_ai_available?).and_return(true)
            end

            context 'when the question is not provided' do
              let(:question) { nil }

              it 'returns an empty response message' do
                expect(execute.response_body).to eq(empty_response_message)
              end
            end

            context 'when no neighbors are found' do
              before do
                allow(model_class).to receive(:neighbor_for).and_return(model_class.none)
                allow(embeddings_client).to receive(api_endpoint).with(**endpoint_args).and_return(embedding_response)
              end

              it 'returns an i do not know' do
                expect(execute.response_body).to eq(empty_response_message)
              end
            end
          end
        end
      end
    end
  end
end
