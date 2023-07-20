# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Chain::Tools::JsonReader::Executor, :aggregate_failures, feature_category: :shared do
  subject(:reader) { described_class.new(context: context, options: options) }

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group, name: "My sweet project with robots in it") }
  let_it_be(:issue) do
    create(:issue, project: project, title: "AI should be included at birthdays", description: description_content)
  end

  let_it_be(:note) { create(:note_on_issue, project: project, noteable: issue, note: note_content) }

  let(:context) do
    Gitlab::Llm::Chain::GitlabContext.new(
      container: project,
      resource: resource,
      current_user: user,
      ai_request: ai_request
    )
  end

  let(:ai_request) { double }
  let(:resource) { issue }
  let(:options) { { suggestions: +"", input: "question" } }
  let(:ai_response) { "It's a response!" }

  before do
    allow(ai_request).to receive(:request).and_return(ai_response)
    allow(reader).to receive(:request).and_return(ai_response)
    stub_const("#{described_class.name}::MAX_TOKENS", 4)
  end

  describe '#name' do
    it 'returns tool name' do
      expect(described_class::NAME).to eq('ResourceReader')
    end
  end

  describe '#description' do
    it 'returns tool description' do
      expect(described_class::DESCRIPTION)
        .to include('Useful tool when you need to get information about specific ' \
                    'resource that was already identified. ' \
                    'Action Input for this tools always starts with: `data`')
    end
  end

  describe '#execute' do
    context 'when execution is successful' do
      context 'when resource length equals or exceeds max tokens' do
        it 'processes the long path' do
          expect(reader).to receive(:process_long_path)

          reader.execute
        end
      end

      context 'when resource length does not exceed max tokens' do
        before do
          stub_const("#{described_class.name}::MAX_TOKENS", 999999)
        end

        it 'processes the short path' do
          expect(reader).to receive(:process_short_path)

          reader.execute
        end

        describe 'processing answer' do
          let(:ai_response) do
            "Please use this information about this resource: #{issue
              .serialize_instance(user: context.current_user).to_json}"
          end

          it "returns a final answer even if the response doesn't contain a 'final answer' token" do
            expect_answer_with_content(ai_response)
          end
        end
      end

      context 'if final answer is present' do
        let(:answer) { "The answer you've been looking for! Made with computers!" }
        let(:ai_response) { "Final Answer: #{answer}" }

        it 'returns a ::Gitlab::Llm::Chain::Answer' do
          expect_answer_with_content(answer)
        end
      end

      context 'when final answer is not present' do
        context 'when the response contains an action' do
          context 'when first action includes JsonReaderListKeys' do
            let(:ai_response) do
              <<~PROMPT
                I should look at the keys that exist in `data` to see what I have access to
                Action: JsonReaderListKeys
                Action Input: data
              PROMPT
            end

            it 'uses `Utils::JsonReaderListKeys`' do
              expect(::Gitlab::Llm::Chain::Utils::JsonReaderListKeys).to receive(:handle_keys)

              expect_and_stop_execution_at(regex: /Observation:/)

              reader.execute
            end
          end

          context 'when action includes JsonReaderGetValue' do
            let(:ai_response) do
              <<~PROMPT
                I should look at the data that exist in `labels` to see what I have access to
                Action: JsonReaderGetValue
                Action Input: data['labels'][0]
              PROMPT
            end

            it 'uses `Utils::JsonReaderGetValue`' do
              expect(::Gitlab::Llm::Chain::Utils::JsonReaderGetValue).to receive(:handle_keys).at_least(:once)

              expect_and_stop_execution_at(regex: /Observation:/)

              reader.execute
            end
          end
        end

        context 'when the response contains no action' do
          let(:ai_response) do
            <<~PROMPT
                Action Input: I'm here for the birthday party. Beep beep boop.
            PROMPT
          end

          it 'does not add an observation to the next recursive call' do
            response = reader.execute
            error_msg = "is not valid, Action must be either `JsonReaderListKeys` or `JsonReaderGetValue`"
            expect(response).to be_a(Gitlab::Llm::Chain::Answer)
            expect(response.content).to include(error_msg)
          end
        end

        context 'when the response does not contain any keywords' do
          let(:ai_response) do
            <<~PROMPT
                I'm here for the birthday party. Beep beep boop.
            PROMPT
          end

          it 'returns final response' do
            expect_answer_with_content(ai_response.strip)
          end
        end
      end
    end
  end

  context 'when resource is not serialisable into JSON' do
    let(:resource) { Class.new }

    # e.g. when `serialize_instance` hasn't been defined on a model
    it 'returns an answer with an error' do
      response = reader.execute

      expect(response).to be_a(Gitlab::Llm::Chain::Answer)
      expect(response.content).to match(/Unexpected error/)
    end
  end
end

def expect_answer_with_content(expected_content)
  expected_params = { status: :ok, context: context, content: expected_content, tool: nil }
  expect(::Gitlab::Llm::Chain::Answer).to receive(:new).with(expected_params).and_call_original

  expect(reader.execute).to be_a(::Gitlab::Llm::Chain::Answer)
end

def expect_and_stop_execution_at(regex:)
  # this is to make sure we get this far into the method
  # but we tell the spec to stop the code before the recursive call
  # which would cause a stack overflow.
  allow(options[:suggestions]).to receive(:<<)
  allow(options[:suggestions]).to receive(:<<).with(regex).and_raise("Stop here please")
end

def description_content
  <<~PROMPT
    I think it would be good to include AI at birthday parties. It could automatically bring in the cake!
    They could even do quality control on the number of candles to ensure nobody is lying about their age.
  PROMPT
end

def note_content
  <<~PROMPT
    AI isn't a robot though, they couldn't bring in the cake because AI is a language model and not a physical robot.
    Disagree.
  PROMPT
end
