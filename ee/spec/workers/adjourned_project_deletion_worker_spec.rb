# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AdjournedProjectDeletionWorker, feature_category: :compliance_management do
  describe "#perform" do
    subject(:worker) { described_class.new }

    let(:user) { create(:user) }
    let(:project) { create(:project, deleting_user: user) }
    let(:service) { instance_double(Projects::DestroyService) }

    it 'executes destroying project' do
      expect(service).to receive(:async_execute)
      expect(Projects::DestroyService).to receive(:new).with(project, user).and_return(service)

      worker.perform(project.id)
    end

    it 'stops execution if user was deleted' do
      project.update!(deleting_user: nil)

      expect(Projects::DestroyService).not_to receive(:new)

      worker.perform(project.id)
    end
  end
end
