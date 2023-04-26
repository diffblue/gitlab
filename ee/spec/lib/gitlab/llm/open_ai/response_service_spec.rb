# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::OpenAi::ResponseService, feature_category: :no_category do # rubocop: disable RSpec/InvalidFeatureCategory
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :public, group: group) }
  let(:response_body) { 'Some response' }
  let(:options) { {} }

  let(:ai_response_json) do
    '{
      "id": "cmpl-72baOZiNHv2njeNoWqPZ12xozfPv7",
      "object": "text_completion",
      "created": 1680855492,
      "model": "text-davinci-003",
      "choices": [
        {
          "text": "Some response",
          "index": 0,
          "logprobs": null,
          "finish_reason": "stop"
        }
      ],
      "usage": {
        "prompt_tokens": 8,
        "completion_tokens": 17,
        "total_tokens": 25
      }
    }'
  end

  shared_examples 'triggers ai completion subscription' do
    it 'triggers subscription' do
      uuid = 'u-u-i-d'
      allow(SecureRandom).to receive(:uuid).and_return(uuid)

      data = {
        id: uuid,
        model_name: resource.class.name,
        response_body: response_body,
        errors: []

      }
      expect(GraphqlTriggers).to receive(:ai_completion_response).with(user.to_global_id, resource.to_global_id, data)

      subject
    end
  end

  shared_examples 'with a markup format option' do
    let(:options) { { markup_format: :html } }

    it_behaves_like 'triggers ai completion subscription' do
      let(:response_body) { '<p data-sourcepos="1:1-1:13" dir="auto">Some response</p>' }
    end
  end

  describe '#execute' do
    subject { described_class.new(user, resource, ai_response_json, options: options).execute }

    let_it_be(:resource) { create(:merge_request, source_project: project) }

    context 'without user' do
      let(:user) { nil }

      it 'does not broadcast subscription' do
        expect(GraphqlTriggers).not_to receive(:ai_completion_response)

        subject
      end
    end

    context 'for a merge request' do
      it_behaves_like 'triggers ai completion subscription'
      it_behaves_like 'with a markup format option'
    end

    context 'for a work item' do
      let_it_be(:resource) { create(:work_item, project: project) }

      it_behaves_like 'triggers ai completion subscription'
      it_behaves_like 'with a markup format option'
    end

    context 'for an issue' do
      let_it_be(:resource) { create(:issue, project: project) }

      it_behaves_like 'triggers ai completion subscription'
      it_behaves_like 'with a markup format option'
    end

    context 'for an epic' do
      let_it_be(:resource) { create(:epic, group: group) }

      it_behaves_like 'triggers ai completion subscription'
      it_behaves_like 'with a markup format option'
    end
  end
end
