# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FeatureGroups::GitlabTeamMembers, feature_category: :shared do
  let(:member) { instance_double('User') }

  describe '#enabled?' do
    it 'returns false' do
      expect(described_class.enabled?(member)).to eq(false)
    end
  end
end
