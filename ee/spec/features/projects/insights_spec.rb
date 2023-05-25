# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project Insights', feature_category: :groups_and_projects do
  it_behaves_like 'Insights page' do
    let_it_be(:entity) { create(:project) }
    let(:path) { project_insights_path(entity) }
    let(:route) do
      project_insights_url(entity)
    end
  end
end
