# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UsersOpsDashboardProjects::DestroyService, feature_category: :groups_and_projects do
  let(:user) { create(:user) }
  let(:service) { described_class.new(user) }
  let(:project) { create(:project, :private) }

  describe '#execute' do
    context 'with an added project' do
      before do
        user.ops_dashboard_projects << project
      end

      it 'removes the project' do
        expect { service.execute(project.id) }.to change { UsersOpsDashboardProject.count }.to(0)
      end

      it 'returns the removed project' do
        removed = service.execute(project.id)

        expect(removed).to eq(project)
      end
    end

    context 'without projects added' do
      it 'does not remove the project' do
        expect { service.execute(project.id) }.not_to change { UsersOpsDashboardProject.count }
      end

      it 'returns nil' do
        expect(service.execute(project.id)).to be_nil
      end
    end
  end
end
