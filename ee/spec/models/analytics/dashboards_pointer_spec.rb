# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::DashboardsPointer, type: :model, feature_category: :devops_reports do
  subject { build(:analytics_dashboards_pointer) }

  it { is_expected.to belong_to(:namespace) }
  it { is_expected.to belong_to(:project) }
  it { is_expected.to belong_to(:target_project).required }

  describe '#validations' do
    let_it_be(:project) { create :project }
    let_it_be(:namespace) { create :namespace }

    it "doesn't allow namespace and project at the same time" do
      subject.namespace = namespace
      subject.project = project

      subject.valid?

      expect(subject.errors.messages[:base]).to include(_('Only one source is required but both were provided'))
    end

    it 'requires namespace or project' do
      subject.namespace = nil
      subject.project = nil

      subject.valid?

      expect(subject.errors.messages[:base]).to include(_('Namespace or project is required'))
    end

    it 'check uniqueness of namespace' do
      create(:analytics_dashboards_pointer, namespace: namespace)

      is_expected.not_to allow_value(namespace.id).for(:namespace_id)
    end

    it 'check uniqueness of project' do
      create(:analytics_dashboards_pointer, project: project, namespace: nil)

      is_expected.not_to allow_value(project.id).for(:project_id)
    end
  end
end
