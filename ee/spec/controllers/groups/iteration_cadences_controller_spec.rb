# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::IterationCadencesController, feature_category: :team_planning do
  let_it_be(:group) { create(:group, :private) }

  it_behaves_like 'accessing iteration cadences' do
    subject { get :index, params: { group_id: group } }
  end
end
