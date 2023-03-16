# frozen_string_literal: true

require "spec_helper"

RSpec.describe MergeRequestResetApprovalsWorker, feature_category: :source_code_management do
  include RepoHelpers

  let(:project) { create(:project) }
  let(:user) { create(:user) }

  subject { described_class.new }

  describe "#perform" do
    let(:newrev) { "789012" }
    let(:ref)    { "refs/heads/test" }

    def perform
      subject.perform(project.id, user.id, ref, newrev)
    end

    it "executes MergeRequests::RefreshService with expected values" do
      expect_next_instance_of(MergeRequests::ResetApprovalsService, project: project, current_user: user) do |refresh_service|
        expect(refresh_service).to receive(:execute).with(ref, newrev)
      end

      perform
    end

    context "project is missing" do
      let(:project) { double("project", id: "foo") }

      it "doesn't execute the service" do
        expect(MergeRequests::ResetApprovalsService).not_to receive(:new)

        perform
      end
    end

    context "user is missing" do
      let(:user) { double("user", id: "foo") }

      it "doesn't execute the service" do
        expect(MergeRequests::ResetApprovalsService).not_to receive(:new)

        perform
      end
    end
  end
end
