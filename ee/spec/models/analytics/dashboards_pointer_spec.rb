# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::DashboardsPointer, type: :model, feature_category: :devops_reports do
  subject(:pointer) { build(:analytics_dashboards_pointer) }

  it { is_expected.to belong_to(:namespace) }
  it { is_expected.to belong_to(:project) }
  it { is_expected.to belong_to(:target_project).required }

  describe '#validations' do
    let_it_be(:project) { create :project }
    let_it_be(:namespace) { create :namespace }

    it "doesn't allow namespace and project at the same time" do
      pointer.namespace = namespace
      pointer.project = project

      pointer.valid?

      expect(pointer.errors.messages[:base]).to include(_('Only one source is required but both were provided'))
    end

    it 'requires namespace or project' do
      pointer.namespace = nil
      pointer.project = nil

      pointer.valid?

      expect(pointer.errors.messages[:base]).to include(_('Namespace or project is required'))
    end

    it 'check uniqueness of namespace' do
      create(:analytics_dashboards_pointer, namespace: namespace)

      is_expected.not_to allow_value(namespace.id).for(:namespace_id)
    end

    it 'check uniqueness of project' do
      create(:analytics_dashboards_pointer, :project_based, project: project)

      is_expected.not_to allow_value(project.id).for(:project_id)
    end

    context 'when the given target_project_id is outside of the group hierarchy' do
      it 'returns validation error' do
        pointer.target_project = create(:project)

        expect(pointer).to be_invalid
        expect(pointer.errors.messages[:base]).to include(_('The selected project is not available'))
      end

      context 'when the existing record has invalid target_project_id' do
        it 'does not mark the record invalid for backward-compatibility reason' do
          pointer = create(:analytics_dashboards_pointer)
          project_outside_the_hierarchy = create(:project)

          # Skip validation
          pointer.update_column(:target_project_id, project_outside_the_hierarchy.id)

          expect(pointer).to be_valid
        end
      end
    end
  end
end
