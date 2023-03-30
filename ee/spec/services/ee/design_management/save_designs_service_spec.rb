# frozen_string_literal: true
require 'spec_helper'

RSpec.describe DesignManagement::SaveDesignsService, feature_category: :design_management do
  include DesignManagementTestHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:design_file) { fixture_file_upload('spec/fixtures/rails_sample.jpg') }
  let_it_be(:design_repository) do
    ::Gitlab::GlRepository::DESIGN.repository_resolver.call(project)
  end

  subject { described_class.new(project, user, issue: issue, files: [design_file]) }

  before do
    enable_design_management
  end

  describe '#execute' do
    before do
      allow_next_instance_of(described_class) do |instance|
        allow(instance).to receive(:repository).and_return(design_repository)
      end
    end

    let(:response) { subject.execute }

    context 'when service is successful' do
      before do
        project.add_developer(user)
      end

      it 'calls repository#log_geo_updated_event', :aggregate_failures do
        expect(design_repository).to receive(:log_geo_updated_event)
        expect(response).to include(status: :success)
      end
    end

    context 'when service errors' do
      it 'does not call repository#log_geo_updated_event', :aggregate_failures do
        expect(design_repository).not_to receive(:log_geo_updated_event)
        expect(response).to include(status: :error)
      end
    end
  end
end
