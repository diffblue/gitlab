# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Chain::Tools::GitlabDocumentation::Executor, :saas, feature_category: :duo_chat do
  describe '#execute' do
    subject(:result) { tool.execute }

    let_it_be(:user) { create(:user) }
    let_it_be_with_reload(:group) { create(:group_with_plan, plan: :ultimate_plan) }

    let(:tool) { described_class.new(context: context, options: options) }
    let(:completion) do
      instance_double(
        'Net::HTTPResponse',
        body: { 'completion' => 'In your User settings. ATTRS: CNT-IDX-123' }.to_json
      )
    end

    let(:response) { Gitlab::Llm::Anthropic::ResponseModifiers::TanukiBot.new(completion.body, user) }
    let(:options) { { input: "how to reset the password?" } }
    let(:context) do
      Gitlab::Llm::Chain::GitlabContext.new(
        container: group,
        resource: user,
        current_user: user,
        ai_request: double
      )
    end

    before do
      group.add_developer(user)
    end

    context 'when context is authorized' do
      include_context 'with ai features enabled for group'

      let(:expected_params) do
        { current_user: user, question: options[:input], tracking_context: { action: 'chat_documentation' } }
      end

      it 'responds with the message from TanukiBot' do
        expect_next_instance_of(Gitlab::Llm::TanukiBot, **expected_params) do |instance|
          expect(instance).to receive(:execute).and_return(response)
        end

        expect(result.content).to eq("In your User settings.")
        expect(result.extras).to eq(sources: [])
      end

      context 'when response is empty' do
        let(:message) { "some message" }
        let(:response) { Gitlab::Llm::ResponseModifiers::EmptyResponseModifier.new(message) }

        it 'responds with the message from TanukiBot' do
          expect_next_instance_of(Gitlab::Llm::TanukiBot, expected_params) do |instance|
            expect(instance).to receive(:execute).and_return(response)
          end

          expect(tool.execute.content).to eq(message)
        end
      end
    end

    context 'when context is not authorized' do
      it 'responds with the message from TanukiBot' do
        expect(result.content)
          .to eq("I am sorry, I am unable to find the documentation answer you are looking for.")
        expect(result.extras).to eq(nil)
      end
    end
  end

  describe '#name' do
    it 'returns tool name' do
      expect(described_class::NAME).to eq('GitlabDocumentation')
    end

    it 'returns tool human name' do
      expect(described_class::HUMAN_NAME).to eq('GitLab Documentation')
    end
  end
end
