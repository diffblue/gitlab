# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ai::Project::Conversations, feature_category: :shared do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  subject { described_class.new(project, user) }

  describe '#ci_config_chat_enabled?' do
    where(:licensed_feature_available, :feature_enabled, :ai_experiments_enabled, :expected_result) do
      true   | true  | true  | true
      true   | true  | false | false
      true   | false | true  | false
      false  | true  | true  | false
      false  | false | false | false
      true   | false | false | false
      false  | false | true  | false
      false  | true  | false | false
    end

    with_them do
      before do
        stub_licensed_features(ai_config_chat: licensed_feature_available)
        stub_feature_flags(ai_ci_config_generator: feature_enabled, openai_experimentation: ai_experiments_enabled)
      end

      it 'returns the features availability' do
        expect(subject.ci_config_chat_enabled?).to eq(expected_result)
      end
    end
  end

  describe '#ci_config_messages' do
    let_it_be(:message1) { create(:message, project: project, user: user) }
    let_it_be(:message2) { create(:message, project: project, user: user) }
    let_it_be(:message3) { create(:message, project: project, user: user) }

    before do
      project2 = create(:project)
      create(:message, project: project2, user: user)
      user2 = create(:user)
      create(:message, project: project, user: user2)
    end

    it 'returns the conversation messages in order' do
      expect(subject.ci_config_messages).to eq([message1, message2, message3])
    end
  end
end
