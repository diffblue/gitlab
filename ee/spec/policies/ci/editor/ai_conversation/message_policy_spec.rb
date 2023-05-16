# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Editor::AiConversation::MessagePolicy, feature_category: :pipeline_composition do
  let_it_be(:message_user) { create(:user) }
  let_it_be(:message_project) { create(:project) }
  let_it_be(:message) { create(:message, project: message_project, user: message_user) }
  let_it_be(:non_message_user) { create(:user) }

  let(:policy) do
    described_class.new(policy_check_user, message)
  end

  context 'when the user created the message' do
    let(:policy_check_user) { message_user }

    context 'when the user is not a project member' do
      it 'dis-allows reading the message' do
        expect(policy).not_to be_allowed :read_ai_message
      end
    end

    context "when the user is a member who can't create a pipeline" do
      before do
        message_project.add_reporter(message_user)
      end

      it 'dis-allows reading the message' do
        expect(policy).not_to be_allowed :read_ai_message
      end
    end

    context "when the user is a member who can create a pipeline" do
      before do
        message_project.add_developer(message_user)
      end

      it 'allows reading the message' do
        expect(policy).to be_allowed :read_ai_message
      end
    end
  end

  context 'when the user did not create the message' do
    let(:policy_check_user) { non_message_user }

    context 'when the user is not a project member' do
      it 'dis-allows reading the message' do
        expect(policy).not_to be_allowed :read_ai_message
      end
    end

    context "when the user is a member who can't create a pipeline" do
      before do
        message_project.add_reporter(message_user)
      end

      it 'dis-allows reading the message' do
        expect(policy).not_to be_allowed :read_ai_message
      end
    end

    context "when the user is a member who can create a pipeline" do
      before do
        message_project.add_developer(message_user)
      end

      it 'dis-allows reading the message' do
        expect(policy).not_to be_allowed :read_ai_message
      end
    end
  end
end
