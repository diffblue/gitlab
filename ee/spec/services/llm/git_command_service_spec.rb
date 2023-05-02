# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Llm::GitCommandService, feature_category: :source_code_management do
  subject { described_class.new(user, user, options) }

  describe '#perform', :saas do
    let_it_be(:ultimate_group) { create(:group_with_plan, plan: :ultimate_plan) }
    let_it_be(:user) { create(:user) }

    let_it_be(:options) do
      {
        prompt: 'list 10 commit titles'
      }
    end

    it 'returns an error' do
      expect(subject.execute).to be_error
    end

    context 'when user is a member of ultimate group' do
      before do
        stub_licensed_features(ai_git_command: true)

        ultimate_group.add_developer(user)
      end

      it 'responds successfully' do
        response = subject.execute

        expect(response).to be_success
        expect(response.payload).to include({
          max_tokens: 300,
          model: "gpt-3.5-turbo",
          temperature: 0.4
        })

        expect(response.payload[:messages][0][:content]).to include(
          "Provide the appropriate git commands for: list 10 commit titles."
        )
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
    end
  end
end
