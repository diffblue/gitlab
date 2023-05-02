# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::TanukiBot, feature_category: :global_search do
  describe '#execute' do
    let_it_be(:user) { create(:user) }
    let_it_be(:embeddings) { create_list(:tanuki_bot_mvc, 2) }

    let(:question) { 'A question' }
    let(:answer) { 'The answer.' }
    let(:logger) { instance_double('Logger') }
    let(:instance) { described_class.new(current_user: user, question: question, logger: logger) }
    let(:openai_client) { ::Gitlab::Llm::OpenAi::Client.new(user) }
    let(:embedding) { Array.new(1536, 0.5) }
    let(:embedding_response) { { "data" => [{ "embedding" => embedding }] } }
    let(:attrs) { embeddings.map(&:id).map { |x| "CNT-IDX-#{x}" }.join(", ") }
    let(:completion_response) { { "choices" => [{ "text" => "#{answer} ATTRS: #{attrs}" }] } }
    let(:status_code) { 200 }
    let(:success) { true }

    subject(:execute) { instance.execute }

    before do
      allow(License).to receive(:feature_available?).and_return(true)
      allow(logger).to receive(:info)
      allow(completion_response).to receive(:code).and_return(status_code)
      allow(completion_response).to receive(:success?).and_return(success)
    end

    context 'with the ai_tanuki_bot license not available' do
      before do
        allow(License).to receive(:feature_available?).with(:ai_tanuki_bot).and_return(false)
      end

      it 'returns an empty hash' do
        expect(execute).to eq({})
      end
    end

    context 'with the tanuki_bot license available' do
      context 'when on Gitlab.com' do
        before do
          allow(::Gitlab).to receive(:com?).and_return(true)
        end

        context 'when no user is provided' do
          let(:user) { nil }

          it 'returns an empty hash' do
            expect(execute).to eq({})
          end
        end

        context 'when the user does not have a paid namespace' do
          before do
            allow(user).to receive(:has_paid_namespace?).and_return(false)
          end

          it 'returns an empty hash' do
            expect(execute).to eq({})
          end
        end

        context 'when the user has a paid namespace' do
          before do
            allow(::Gitlab::Llm::OpenAi::Client).to receive(:new).and_return(openai_client)
            allow(user).to receive(:has_paid_namespace?).and_return(true)
          end

          it 'executes calls through to open ai' do
            embeddings

            expect(openai_client).to receive(:completions).exactly(3).times.and_return(completion_response)
            expect(openai_client).to receive(:embeddings).and_return(embedding_response)
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

          it 'returns an empty hash' do
            expect(execute).to eq({})
          end
        end
      end

      context 'when the feature flags are enabled' do
        before do
          allow(completion_response).to receive(:parsed_response).and_return(completion_response)
          allow(::Gitlab::Llm::OpenAi::Client).to receive(:new).and_return(openai_client)
        end

        context 'when the question is not provided' do
          let(:question) { nil }

          it 'returns an empty hash' do
            expect(execute).to eq({})
          end
        end

        context 'when no neighbors are found' do
          before do
            allow(Embedding::TanukiBotMvc).to receive(:neighbor_for).and_return(Embedding::TanukiBotMvc.none)
            allow(openai_client).to receive(:embeddings).with(input: question).and_return(embedding_response)
          end

          it 'returns an i do not know' do
            expect(execute).to eq({
              msg: 'I do not know.',
              sources: []
            })
          end
        end

        [true, false].each do |parallel_bot|
          context "with tanuki_bot_parallel set to #{parallel_bot}" do
            before do
              stub_feature_flags(tanuki_bot_parallel: parallel_bot)
            end

            describe 'getting matching documents' do
              before do
                allow(openai_client).to receive(:completions).and_return(completion_response)
              end

              it 'creates an embedding for the question' do
                expect(openai_client).to receive(:embeddings).with(input: question).and_return(embedding_response)

                execute
              end

              it 'queries the embedding database for nearest neighbors' do
                allow(openai_client).to receive(:embeddings).with(input: question).and_return(embedding_response)

                expect(::Embedding::TanukiBotMvc).to receive(:neighbor_for)
                  .with(embedding,
                    limit: described_class::RECORD_LIMIT,
                    minimum_distance: described_class::MINIMUM_DISTANCE)
                  .and_call_original.once

                execute
              end

              context 'when an error is returned' do
                let(:final_completion_response) { { error: { message: 'something went wrong' } } }

                before do
                  allow(openai_client).to receive(:completions).with(hash_including(prompt: /create a final answer/))
                    .and_return(final_completion_response)
                  allow(final_completion_response).to receive(:code).and_return(500)
                  allow(final_completion_response).to receive(:success?).and_return(false)
                end

                it 'raises an error when an error is returned' do
                  allow(openai_client).to receive(:embeddings).with(input: question).and_return(embedding_response)

                  expect { execute }.to raise_error(RuntimeError, /something went wrong/)
                end
              end
            end

            describe 'checking documents for relevance and summarizing' do
              before do
                allow(openai_client).to receive(:embeddings).and_return(embedding_response)
              end

              it 'calls the completions API once for each document and once for summarizing' do
                expect(openai_client).to receive(:completions)
                  .with(hash_including(prompt: /see if any of the text is relevant to answer the question/))
                  .and_return(completion_response).twice

                expect(openai_client).to receive(:completions)
                  .with(hash_including(prompt: /create a final answer/))
                  .and_return(completion_response).once

                execute
              end
            end
          end
        end
      end
    end
  end
end
