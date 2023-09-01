# frozen_string_literal: true
require 'spec_helper'

RSpec.describe DesignManagement::DeleteDesignsService, feature_category: :design_management do
  include DesignManagementTestHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:design_repository) { project.find_or_create_design_management_repository.repository }

  let!(:design) { create(:design, :with_lfs_file, issue: issue) }

  subject { described_class.new(project, user, issue: issue, designs: [design]) }

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
