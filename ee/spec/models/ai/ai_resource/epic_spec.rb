# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ai::AiResource::Epic, feature_category: :duo_chat do
  describe '#serialize_for_ai' do
    let(:epic) { build(:epic) }
    let(:user) { build(:user) }

    subject(:wrapped_epic) { described_class.new(epic) }

    it 'calls the serializations class' do
      expect(EpicSerializer).to receive_message_chain(:new, :represent)
                                  .with(current_user: user)
                                  .with(epic, {
                                    user: user,
                                    notes_limit: 100,
                                    serializer: 'ai',
                                    resource: wrapped_epic
                                  })

      wrapped_epic.serialize_for_ai(user: user, content_limit: 100)
    end
  end
end
