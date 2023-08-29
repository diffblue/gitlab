# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['AiResponse'], feature_category: :duo_chat do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }

  it { expect(described_class.graphql_name).to eq('AiResponse') }

  it 'has the expected fields' do
    expected_fields = %w[id request_id content content_html role type timestamp errors]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end

  describe '#id' do
    let(:ai_response) { { id: '123' } }

    it 'renders html through Banzai' do
      resolved_field = resolve_field(:id, ai_response, current_user: current_user)

      expect(resolved_field).to eq('123')
    end
  end

  describe '#content_html' do
    let(:ai_response) { { content: 'foo' } }

    it 'renders html through Banzai' do
      allow(Banzai).to receive(:render_and_post_process).with(ai_response[:content], {
        current_user: current_user,
        only_path: false,
        pipeline: :full,
        allow_comments: false,
        skip_project_check: true
      }).and_return('banzai_content')

      resolved_field = resolve_field(:content_html, ai_response, current_user: current_user)

      expect(resolved_field).to eq('banzai_content')
    end
  end
end
