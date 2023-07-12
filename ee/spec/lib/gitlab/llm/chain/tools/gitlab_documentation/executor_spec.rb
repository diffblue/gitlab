# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Chain::Tools::GitlabDocumentation::Executor, :saas, feature_category: :shared do
  describe '#execute' do
    let(:response) do
      instance_double(
        'Net::HTTPResponse',
        body: { 'completion' => 'In your User settings. ATTRS: CNT-IDX-123' }.to_json
      )
    end

    let(:options) { { input: "how to reset the password?" } }
    let(:context) do
      Gitlab::Llm::Chain::GitlabContext.new(
        container: group,
        resource: user,
        current_user: user,
        ai_request: double
      )
    end

    let_it_be(:user) { create(:user) }
    let_it_be_with_reload(:group) { create(:group_with_plan, plan: :ultimate_plan) }

    subject(:tool) { described_class.new(context: context, options: options) }

    before do
      group.add_developer(user)
    end

    context 'when context is authorized' do
      include_context 'with ai features enabled for group'

      it 'responds with the message from TanukiBot' do
        expect_next_instance_of(Gitlab::Llm::TanukiBot, current_user: user, question: options[:input]) do |instance|
          expect(instance).to receive(:execute).and_return(response)
        end

        expect(tool.execute.content).to eq("{\"content\":\"In your User settings.\",\"sources\":[]}")
      end
    end

    context 'when context is not authorized' do
      it 'responds with the message from TanukiBot' do
        expect(tool.execute.content)
          .to eq("I am sorry, I am unable to find the documentation answer you are looking for.")
      end
    end
  end
end
