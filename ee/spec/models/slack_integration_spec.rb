# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SlackIntegration do
  describe "Associations" do
    it { is_expected.to belong_to(:integration) }
  end

  describe 'Scopes' do
    let_it_be(:with_bot) { create(:slack_integration) }
    let_it_be(:without_bot) { create(:slack_integration, :legacy) }

    describe '#with_bot' do
      it 'returns records with bot data' do
        expect(described_class.with_bot).to contain_exactly(with_bot)
      end
    end
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:team_id) }
    it { is_expected.to validate_presence_of(:team_name) }
    it { is_expected.to validate_presence_of(:alias) }
    it { is_expected.to validate_presence_of(:user_id) }
    it { is_expected.to validate_presence_of(:integration) }
  end
end
