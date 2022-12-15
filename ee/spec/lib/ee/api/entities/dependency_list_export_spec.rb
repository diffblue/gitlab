# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::EE::API::Entities::DependencyListExport, feature_category: :dependency_management do
  let_it_be(:project) { build_stubbed(:project, id: 1) }
  let_it_be(:dependency_list_export) { build_stubbed(:dependency_list_export, :finished, id: 1, project: project) }

  let(:entity) { described_class.new(dependency_list_export) }

  subject { entity.as_json }

  it 'contains a small set of dependency list export properties', :aggregate_failures do
    expect(subject[:id]).to eq(dependency_list_export.id)
    expect(subject[:has_finished]).to eq(dependency_list_export.finished?)
    expect(subject[:self]).to end_with(
      "/api/v4/projects/#{project.id}/dependency_list_exports/#{dependency_list_export.id}")
    expect(subject[:download]).to end_with(
      "/api/v4/projects/#{project.id}/dependency_list_exports/#{dependency_list_export.id}/download")
  end
end
