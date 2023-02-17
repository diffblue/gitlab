# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Epics::BaseService, feature_category: :team_planning do
  describe '#constructor_container_arg' do
    it { expect(described_class.constructor_container_arg("some-value")).to eq({ group: "some-value" }) }
  end
end
