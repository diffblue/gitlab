# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Completions::Chat, feature_category: :shared do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:resource) { create(:issue, project: project) }

  let(:content) { 'Summarize issue' }
  let(:ai_client) { instance_double(Gitlab::Llm::Anthropic::Client) }
  let(:context) { instance_double(Gitlab::Llm::Chain::GitlabContext) }
  let(:options) { { request_id: 'uuid', content: content } }
  let(:answer) do
    ::Gitlab::Llm::Chain::Answer.new(
      status: :ok, context: context, content: content, tool: nil, is_final: true
    )
  end

  subject { described_class.new(nil).execute(user, resource, options) }

  describe '#execute' do
    before do
      allow(::Gitlab::Llm::Anthropic::Client).to receive(:new).and_return(ai_client)
    end

    it 'calls the ZeroShot Agent with the right parameters' do
      expected_params = [
        user_input: content,
        tools: match_array([::Gitlab::Llm::Chain::Tools::IssueIdentifier]),
        context: context
      ]

      expect_next_instance_of(::Gitlab::Llm::Chain::Agents::ZeroShot, *expected_params) do |instance|
        expect(instance).to receive(:execute).and_return(answer)
      end

      expect(::Gitlab::Llm::Chain::GitlabContext).to receive(:new)
        .with(current_user: user, container: group, resource: resource, ai_client: ai_client).and_return(context)

      subject
    end
  end
end
