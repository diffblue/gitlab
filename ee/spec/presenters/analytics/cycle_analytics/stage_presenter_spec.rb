# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::CycleAnalytics::StagePresenter do
  let(:default_stage_params) { Gitlab::Analytics::CycleAnalytics::DefaultStages.params_for_issue_stage }
  let(:default_stage) { Analytics::CycleAnalytics::Stage.new(default_stage_params) }
  let(:custom_stage) { Analytics::CycleAnalytics::Stage.new(name: 'Hello') }

  describe '#title' do
    it 'returns the pre-defined title for the default stage' do
      decorator = described_class.new(default_stage)

      expect(decorator.title).to eq(s_('CycleAnalyticsStage|Issue'))
    end

    it 'returns the name attribute for a custom stage' do
      decorator = described_class.new(custom_stage)

      expect(decorator.title).to eq(custom_stage.name)
    end
  end

  describe '#description' do
    it 'returns the pre-defined description for the default stage' do
      decorator = described_class.new(default_stage)

      expect(decorator.description).to eq(_('Time before an issue gets scheduled'))
    end

    it 'returns empty string when custom stage is given' do
      decorator = described_class.new(custom_stage)

      expect(decorator.description).to eq('') # custom stages don't have description
    end
  end
end
