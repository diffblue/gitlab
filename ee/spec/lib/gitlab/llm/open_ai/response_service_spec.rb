# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::OpenAi::ResponseService, feature_category: :no_category do # rubocop: disable RSpec/InvalidFeatureCategory
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :public, group: group) }

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

  RSpec.shared_examples 'triggers ai completion subscription' do
    it 'triggers subscription' do
      uuid = 'u-u-i-d'
      allow(SecureRandom).to receive(:uuid).and_return(uuid)

      data = {
        id: uuid,
        model_name: resource.class.name,
        response_body: 'Some response',
        errors: []

      }
      expect(GraphqlTriggers).to receive(:ai_completion_response).with(user.to_global_id, resource.to_global_id, data)

      subject
    end
  end

  describe '#execute' do
    subject { described_class.new(user, resource, ai_response_json, options: {}).execute }

    context 'without user' do
      let_it_be(:resource) { create(:merge_request, source_project: project) }

      let(:user) { nil }

      it 'does not broadcast subscription' do
        expect(GraphqlTriggers).not_to receive(:ai_completion_response)

        subject
      end
    end

    context 'for a merge request' do
      let_it_be(:resource) { create(:merge_request, source_project: project) }

      it_behaves_like 'triggers ai completion subscription'
    end

    context 'for an issue' do
      let_it_be(:resource) { create(:issue, project: project) }

      it_behaves_like 'triggers ai completion subscription'
    end

    context 'for an epic' do
      let_it_be(:resource) { create(:epic, group: group) }

      it_behaves_like 'triggers ai completion subscription'
    end
  end
end
