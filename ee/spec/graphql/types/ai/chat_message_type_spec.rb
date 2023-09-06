# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['AiChatMessage'], feature_category: :duo_chat do
  include GraphqlHelpers

  it { expect(described_class.graphql_name).to eq('AiChatMessage') }

  it 'has the expected fields' do
    expected_fields = %w[id request_id content content_html role timestamp errors]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end

  describe '#content_html' do
    let_it_be(:current_user) { create(:user) }

    let(:message) { Gitlab::Llm::ChatMessage.new('content' => "Hello, **World**!", 'timestamp' => '') }

    it 'renders html through Banzai' do
      allow(Banzai).to receive(:render_and_post_process).with(message.content, {
        current_user: current_user,
        only_path: false,
        pipeline: :full,
        allow_comments: false,
        skip_project_check: true
      }).and_return('banzai_content')

      resolved_field = resolve_field(:content_html, message, current_user: current_user)

      expect(resolved_field).to eq('banzai_content')
    end
  end
end
