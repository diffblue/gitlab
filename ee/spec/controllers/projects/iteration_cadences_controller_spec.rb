# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::IterationCadencesController, feature_category: :team_planning do
  let_it_be(:group) { create(:group, :private) }
  let_it_be(:project) { create(:project, namespace: group) }

  it_behaves_like 'accessing iteration cadences' do
    subject { get :index, params: { namespace_id: project.namespace, project_id: project } }
  end
end
