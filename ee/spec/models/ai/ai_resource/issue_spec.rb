# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ai::AiResource::Issue, feature_category: :duo_chat do
  describe '#serialize_for_ai' do
    let(:issue) { build(:issue) }
    let(:user) { build(:user) }

    subject(:wrapped_issue) { described_class.new(issue) }

    it 'calls the serializations class' do
      expect(::IssueSerializer).to receive_message_chain(:new, :represent)
                                     .with(current_user: user, project: issue.project)
                                     .with(issue, {
                                       user: user,
                                       notes_limit: 100,
                                       serializer: 'ai',
                                       resource: wrapped_issue
                                     })
      wrapped_issue.serialize_for_ai(user: user, content_limit: 100)
    end
  end
end
