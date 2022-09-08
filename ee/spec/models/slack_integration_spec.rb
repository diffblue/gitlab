# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SlackIntegration do
  describe "Associations" do
    it { is_expected.to belong_to(:integration) }
  end

  describe 'Scopes' do
    let_it_be(:slack_integration) { create(:slack_integration) }
    let_it_be(:legacy_slack_integration) { create(:slack_integration, :legacy) }

    describe '#with_bot' do
      it 'returns records with bot data' do
        expect(described_class.with_bot).to contain_exactly(slack_integration)
      end
    end

    describe '#by_team' do
      it 'returns records with shared team_id' do
        team_id = slack_integration.team_id
        team_slack_integration = create(:slack_integration, team_id: team_id)

        expect(described_class.by_team(team_id)).to contain_exactly(slack_integration, team_slack_integration)
      end
    end

    describe '#legacy_by_team' do
      it 'returns records with shared team_id and no bot data' do
        team_id = legacy_slack_integration.team_id
        create(:slack_integration, team_id: team_id)

        expect(described_class.legacy_by_team(team_id)).to contain_exactly(legacy_slack_integration)
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
