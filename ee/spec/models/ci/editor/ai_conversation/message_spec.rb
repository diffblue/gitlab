# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Editor::AiConversation::Message, feature_category: :pipeline_composition do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  let_it_be(:message1) { create(:message, project: project, user: user, created_at: 1.day.ago) }
  let_it_be(:message2) { create(:message, project: project, user: user, created_at: 1.hour.ago) }
  let_it_be(:message3) { create(:message, project: project, user: user, created_at: Time.current) }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:user) }
  end

  describe 'scopes' do
    describe '.belonging_to' do
      subject { described_class.belonging_to(project, user) }

      it 'returns messages belonging to the project and user' do
        expect(subject).to match_array([message1, message2, message3])
      end
    end

    describe '.asc' do
      it 'returns messages in ascending order' do
        expect(described_class.asc).to eq([message1, message2, message3])
      end
    end

    describe '.desc' do
      it 'returns messages in descending order' do
        expect(described_class.desc).to eq([message3, message2, message1])
      end
    end

    describe '.first_pair' do
      it 'returns the earliest two message pair created' do
        expect(described_class.first_pair(project, user)).to match_array([message1, message2])
      end
    end
  end

  describe '#fetching?' do
    where(:role, :async_errors, :content, :expected_result) do
      Gitlab::Llm::OpenAi::Options::SYSTEM_ROLE   | ['Some error'] | 'Some content' | false
      Gitlab::Llm::OpenAi::Options::SYSTEM_ROLE   | ['Some error'] | nil            | false
      Gitlab::Llm::OpenAi::Options::SYSTEM_ROLE   | []            | 'Some content' | false
      Gitlab::Llm::OpenAi::Options::SYSTEM_ROLE   | []            | nil            | false
      Gitlab::Llm::OpenAi::Options::DEFAULT_ROLE  | ['Some error'] | 'Some content' | false
      Gitlab::Llm::OpenAi::Options::DEFAULT_ROLE  | ['Some error'] | nil            | false
      Gitlab::Llm::OpenAi::Options::DEFAULT_ROLE  | []            | 'Some content' | false
      Gitlab::Llm::OpenAi::Options::DEFAULT_ROLE  | []            | nil            | false
      Gitlab::Llm::OpenAi::Options::AI_ROLE       | ['Some error'] | 'Some content' | false
      Gitlab::Llm::OpenAi::Options::AI_ROLE       | ['Some error'] | nil            | false
      Gitlab::Llm::OpenAi::Options::AI_ROLE       | []            | 'Some content' | false
      Gitlab::Llm::OpenAi::Options::AI_ROLE       | []            | nil            | true
    end

    with_them do
      before do
        message1.role = role
        message1.async_errors = async_errors
        message1.content = content
      end

      it "returns true if fetching the ai response" do
        expect(message1.fetching?).to eq(expected_result)
      end
    end
  end
end
