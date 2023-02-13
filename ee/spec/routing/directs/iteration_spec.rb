# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Custom URLs', 'iteration', feature_category: :team_planning do
  describe 'iteration' do
    context 'with group' do
      let(:group) { build_stubbed(:group) }
      let(:cadence) { build_stubbed(:iterations_cadence, group: group) }
      let(:iteration) { build_stubbed(:iteration, group: group, iterations_cadence: cadence) }

      it 'creates directs' do
        expect(iteration_path(iteration)).to eq(group_iteration_path(group, iteration.id))
        expect(iteration_url(iteration)).to eq(group_iteration_url(group, iteration.id))
      end
    end
  end
end
