# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Autocomplete::IterationEntity, feature_category: :team_planning do
  let(:group) { build_stubbed(:group) }
  let(:iteration) { build_stubbed(:iteration, iterations_cadence: build_stubbed(:iterations_cadence, group: group)) }

  describe '#represent' do
    subject { described_class.new(iteration).as_json }

    it 'includes the id, title, and reference' do
      expect(subject).to include(:id, :title, :reference)
    end
  end
end
