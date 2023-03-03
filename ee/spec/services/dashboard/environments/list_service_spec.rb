# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dashboard::Environments::ListService, feature_category: :continuous_delivery do
  describe '#execute' do
    def setup
      user = create(:user)
      project = create(:project, :repository)
      project.add_developer(user)
      user.update!(ops_dashboard_projects: [project])

      [user, project]
    end

    before do
      stub_licensed_features(operations_dashboard: true)
    end

    it 'returns a list of projects' do
      user, project = setup

      projects_with_environments = described_class.new(user).execute

      expect(projects_with_environments).to eq([project])
    end

    context 'when unlicensed' do
      before do
        stub_licensed_features(operations_dashboard: false)
      end

      it 'returns an empty array' do
        user = create(:user)
        project = create(:project)
        project.add_developer(user)
        user.update!(ops_dashboard_projects: [project])

        projects_with_environments = described_class.new(user).execute

        expect(projects_with_environments).to eq([])
      end
    end
  end
end
