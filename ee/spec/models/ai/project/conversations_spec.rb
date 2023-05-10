# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ai::Project::Conversations, feature_category: :not_owned do # rubocop:disable RSpec/InvalidFeatureCategory
  describe '#ci_config_messages' do
    let_it_be(:project) { create(:project) }
    let_it_be(:user) { create(:user) }
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
      expect(
        described_class.new(project, user).ci_config_messages
      ).to eq([message1, message2, message3])
    end
  end
end
