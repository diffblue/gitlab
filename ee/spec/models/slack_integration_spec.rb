# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SlackIntegration do
  describe "Associations" do
    it { is_expected.to belong_to(:integration) }
  end

  describe 'authorized_scope_names' do
    subject(:slack_integration) { create(:slack_integration) }

    it 'accepts assignment to nil' do
      slack_integration.update!(authorized_scope_names: nil)

      expect(slack_integration.authorized_scope_names).to be_empty
    end

    it 'accepts assignment to a string' do
      slack_integration.update!(authorized_scope_names: 'foo')

      expect(slack_integration.authorized_scope_names).to contain_exactly('foo')
    end

    it 'accepts assignment to an array of strings' do
      slack_integration.update!(authorized_scope_names: %w[foo bar])

      expect(slack_integration.authorized_scope_names).to contain_exactly('foo', 'bar')
    end

    it 'accepts assignment to a comma-separated string' do
      slack_integration.update!(authorized_scope_names: 'foo,bar')

      expect(slack_integration.authorized_scope_names).to contain_exactly('foo', 'bar')
    end

    it 'strips white-space' do
      slack_integration.update!(authorized_scope_names: 'foo , bar,baz')

      expect(slack_integration.authorized_scope_names).to contain_exactly('foo', 'bar', 'baz')
    end
  end

  describe 'feature_available?' do
    subject(:slack_integration) { create(:slack_integration) }

    context 'without any scopes' do
      it 'is always false' do
        expect(slack_integration).not_to be_feature_available(:commands)
        expect(slack_integration).not_to be_feature_available(:notifications)
        expect(slack_integration).not_to be_feature_available(:foo)
      end
    end

    context 'with enough scopes for notifications' do
      before do
        slack_integration.update!(authorized_scope_names: %w[chat:write.public chat:write foo])
      end

      it 'only has the correct features' do
        expect(slack_integration).not_to be_feature_available(:commands)
        expect(slack_integration).to be_feature_available(:notifications)
        expect(slack_integration).not_to be_feature_available(:foo)
      end
    end

    context 'with enough scopes for commands' do
      before do
        slack_integration.update!(authorized_scope_names: %w[commands foo])
      end

      it 'only has the correct features' do
        expect(slack_integration).to be_feature_available(:commands)
        expect(slack_integration).not_to be_feature_available(:notifications)
        expect(slack_integration).not_to be_feature_available(:foo)
      end
    end

    context 'with all scopes' do
      before do
        slack_integration.update!(authorized_scope_names: %w[commands chat:write chat:write.public])
      end

      it 'only has the correct features' do
        expect(slack_integration).to be_feature_available(:commands)
        expect(slack_integration).to be_feature_available(:notifications)
        expect(slack_integration).not_to be_feature_available(:foo)
      end
    end
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
