# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Processable, feature_category: :continuous_integration do
  describe 'delegations' do
    subject { described_class.new }

    it { is_expected.to delegate_method(:merge_train_pipeline?).to(:pipeline) }
  end
end
