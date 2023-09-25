# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['AiMessage'], feature_category: :duo_chat do
  include GraphqlHelpers

  let_it_be(:current_user) { build_stubbed(:user) }

  it { expect(described_class.graphql_name).to eq('AiMessage') }

  it 'has the expected fields' do
    expected_fields = %w[id request_id content content_html role timestamp errors type chunk_id]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end

  describe '#id' do
    let(:expected_id) { '123' }
    let(:message) { Gitlab::Llm::ChatMessage.new('id' => expected_id, 'timestamp' => '') }

    it 'returns message gid' do
      resolved_field = resolve_field(:id, message, current_user: current_user)

      expect(resolved_field).to eq(message.to_global_id)
    end

    context 'when message is a hash' do
      it 'returns message id' do
        resolved_field = resolve_field(:id, { id: expected_id }, current_user: current_user)

        expect(resolved_field).to eq(expected_id)
      end
    end
  end

  describe '#content_html' do
    let(:message) { Gitlab::Llm::ChatMessage.new('content' => content, 'timestamp' => '') }
    let(:content) { "Hello, **World**!" }

    before do
      allow(Banzai).to receive(:render_and_post_process).with(content, {
        current_user: current_user,
        only_path: false,
        pipeline: :full,
        allow_comments: false,
        skip_project_check: true
      }).and_return('banzai_content')
    end

    it 'renders html through Banzai' do
      resolved_field = resolve_field(:content_html, message, current_user: current_user)

      expect(resolved_field).to eq('banzai_content')
    end

    context 'when message is a hash' do
      it 'renders html through Banzai' do
        resolved_field = resolve_field(:content_html, { content: content }, current_user: current_user)

        expect(resolved_field).to eq('banzai_content')
      end
    end
  end
end
