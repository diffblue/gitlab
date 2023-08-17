# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Chain::Tools::Tool, feature_category: :shared do
  let_it_be(:user) { create(:user) }

  let(:options) { {} }
  let(:ai_request_double) { instance_double(Gitlab::Llm::Chain::Requests::Anthropic) }

  let(:context) do
    Gitlab::Llm::Chain::GitlabContext.new(
      current_user: user,
      container: nil,
      resource: user,
      ai_request: ai_request_double,
      tools_used: [Gitlab::Llm::Chain::Tools::IssueIdentifier]
    )
  end

  subject { described_class.new(context: context, options: options) }

  describe '#execute' do
    it 'raises NotImplementedError' do
      expect { subject.authorize }.to raise_error(NotImplementedError)
    end

    context 'when authorize returns true' do
      before do
        allow(subject).to receive(:authorize).and_return(true)
        allow(subject).to receive(:perform)
      end

      it 'calls perform' do
        expect(subject).to receive(:perform)
        subject.execute
      end
    end

    context 'when authorize returns false' do
      before do
        allow(subject).to receive(:authorize).and_return(false)
        allow(subject).to receive(:not_found)
      end

      it 'calls not_found' do
        expect(subject).to receive(:not_found)
        subject.execute
      end
    end

    context 'when tool already used' do
      it 'returns already used answer' do
        allow(subject).to receive(:already_used?).and_return(true)

        content = "You already have the answer from #{described_class::NAME} tool, read carefully."
        answer = subject.execute

        expect(answer.content).to eq(content)
        expect(answer.status).to eq(:not_executed)
      end
    end
  end

  describe '#perform' do
    it 'raises NotImplementedError' do
      expect { subject.perform }.to raise_error(NotImplementedError)
    end
  end

  describe '#group_from_context' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, group: group) }

    it 'returns group if it is set as container' do
      context = Gitlab::Llm::Chain::GitlabContext.new(
        current_user: user,
        container: group,
        resource: user,
        ai_request: ai_request_double,
        tools_used: [Gitlab::Llm::Chain::Tools::IssueIdentifier]
      )

      expect(described_class.new(context: context, options: options).group_from_context).to eq(group)
    end

    it 'returns parent group if project is set as container' do
      context = Gitlab::Llm::Chain::GitlabContext.new(
        current_user: user,
        container: project,
        resource: user,
        ai_request: ai_request_double,
        tools_used: [Gitlab::Llm::Chain::Tools::IssueIdentifier]
      )

      expect(described_class.new(context: context, options: options).group_from_context).to eq(group)
    end

    it 'returns parent group if project is set as container' do
      context = Gitlab::Llm::Chain::GitlabContext.new(
        current_user: user,
        container: project.project_namespace,
        resource: user,
        ai_request: ai_request_double,
        tools_used: [Gitlab::Llm::Chain::Tools::IssueIdentifier]
      )

      expect(described_class.new(context: context, options: options).group_from_context).to eq(group)
    end
  end
end
