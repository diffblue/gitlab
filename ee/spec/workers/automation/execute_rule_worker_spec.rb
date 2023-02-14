# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Automation::ExecuteRuleWorker, feature_category: :no_code_automation do
  let(:worker) { described_class.new }
  let(:rule_id) { 1 }

  describe '#perform' do
    it 'logs placeholder message for now' do
      expect(Gitlab::AppLogger).to receive(:info)
        .with('Placeholder for performing automation rules')

      worker.perform(rule_id)
    end
  end
end
