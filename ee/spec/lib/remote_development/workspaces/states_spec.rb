# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe RemoteDevelopment::Workspaces::States, feature_category: :remote_development do
  let(:object) { Object.new.extend(described_class) }

  describe '.valid_desired_state?' do
    it 'returns true for a valid desired state' do
      expect(object.valid_desired_state?(RemoteDevelopment::Workspaces::States::RESTART_REQUESTED)).to be(true)
    end

    it 'returns false for an invalid desired state' do
      expect(object.valid_desired_state?(RemoteDevelopment::Workspaces::States::FAILED)).to be(false)
    end
  end

  describe '.valid_actual_state?' do
    it 'returns true for a valid actual state' do
      expect(object.valid_actual_state?(RemoteDevelopment::Workspaces::States::RUNNING)).to be(true)
    end

    it 'returns false for an invalid actual state' do
      expect(object.valid_actual_state?(RemoteDevelopment::Workspaces::States::RESTART_REQUESTED)).to be(false)
    end
  end
end
