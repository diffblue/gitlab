# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::Internal, feature_category: :user_profile do
  shared_examples 'bot users' do |bot_type|
    it 'creates the user if it does not exist' do
      expect do
        described_class.public_send(bot_type)
      end.to change { User.where(user_type: bot_type).count }.by(1)
    end

    it 'creates a route for the namespace of the created user' do
      bot_user = described_class.public_send(bot_type)

      expect(bot_user.namespace.route).to be_present
    end

    it 'does not create a new user if it already exists' do
      described_class.public_send(bot_type)

      expect do
        described_class.public_send(bot_type)
      end.not_to change { User.count }
    end
  end

  it_behaves_like 'bot users', :visual_review_bot
  it_behaves_like 'bot users', :suggested_reviewers_bot
end
