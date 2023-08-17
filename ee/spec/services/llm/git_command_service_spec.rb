# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Llm::GitCommandService, feature_category: :source_code_management do
  subject { described_class.new(user, user, options) }

  describe '#perform', :saas do
    let_it_be_with_reload(:group) { create(:group_with_plan, plan: :ultimate_plan) }
    let_it_be(:user) { create(:user) }

    let(:model) { 'vertexai' }

    let(:options) do
      {
        prompt: 'list 10 commit titles',
        model: model
      }
    end

    include_context 'with ai features enabled for group'

    it 'returns an error' do
      expect(subject.execute).to be_error
    end

    context 'when user is a member of ultimate group' do
      before do
        stub_licensed_features(ai_git_command: true)

        group.add_developer(user)
      end

      it 'responds successfully with VertexAI formatted params' do
        stub_ee_application_setting(vertex_ai_host: 'host', vertex_ai_project: 'c')

        allow_next_instance_of(::Gitlab::Llm::VertexAi::Configuration) do |instance|
          allow(instance).to receive(:access_token).and_return('access token')
        end

        response = subject.execute

        expect(response).to be_success
        expect(response.payload).to include({
          url: "https://host/v1/projects/c/locations/us-central1/publishers/google/models/codechat-bison:predict",
          headers: {
            "Accept" => "application/json",
            "Authorization" => "Bearer access token",
            "Content-Type" => "application/json",
            "Host" => "host"
          }
        })

        expect(::Gitlab::Json.parse(response.payload[:body])['instances'][0]['messages']).to eq([{
          'author' => 'content',
          'content' => "Provide the appropriate git commands for: list 10 commit titles.\n"
        }])
      end

      context 'when ai_git_command_ff feature flag is disabled' do
        before do
          stub_feature_flags(ai_git_command_ff: false)
        end

        it 'returns an error' do
          expect(subject.execute).to be_error
        end
      end

      it 'returns an error when messages are too big' do
        stub_const("#{described_class}::INPUT_CONTENT_LIMIT", 4)

        expect(subject.execute).to be_error
      end

      context 'when openai model is requested' do
        let(:model) { 'openai' }

        it 'responds successfully with OpenAI formatted params' do
          response = subject.execute

          expect(response).to be_success
          expect(response.payload).to include({
            max_tokens: 200,
            model: "gpt-3.5-turbo",
            temperature: 0.4
          })

          expect(response.payload[:messages][0][:content]).to include(
            "Provide the appropriate git commands for: list 10 commit titles."
          )
        end
      end
    end
  end
end
