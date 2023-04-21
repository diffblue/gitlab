# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeTrains::RefreshService, feature_category: :merge_trains do
  include ExclusiveLeaseHelpers

  let(:project) { create(:project) }
  let_it_be(:maintainer_1) { create(:user) }
  let_it_be(:maintainer_2) { create(:user) }

  let(:service) { described_class.new(merge_request.target_project_id, merge_request.target_branch) }

  before do
    project.add_maintainer(maintainer_1)
    project.add_maintainer(maintainer_2)
  end

  describe '#execute', :clean_gitlab_redis_queues do
    subject { service.execute }

    let!(:merge_request_1) do
      create(:merge_request, :on_train,
        train_creator: maintainer_1,
        source_branch: 'feature', source_project: project,
        target_branch: 'master', target_project: project)
    end

    let!(:merge_request_2) do
      create(:merge_request, :on_train,
        train_creator: maintainer_2,
        source_branch: 'signed-commits', source_project: project,
        target_branch: 'master', target_project: project)
    end

    let(:refresh_service_1) { double }
    let(:refresh_service_2) { double }
    let(:refresh_service_1_result) { { status: :success } }
    let(:refresh_service_2_result) { { status: :success } }

    before do
      allow(MergeTrains::RefreshMergeRequestService)
        .to receive(:new).with(project, maintainer_1, anything) { refresh_service_1 }
      allow(MergeTrains::RefreshMergeRequestService)
        .to receive(:new).with(project, maintainer_2, anything) { refresh_service_2 }

      allow(refresh_service_1).to receive(:execute) { refresh_service_1_result }
      allow(refresh_service_2).to receive(:execute) { refresh_service_2_result }
    end

    context 'when merge request 1 is passed' do
      let(:merge_request) { merge_request_1 }

      it 'executes RefreshMergeRequestService to all the following merge requests' do
        expect(refresh_service_1).to receive(:execute).with(merge_request_1)
        expect(refresh_service_2).to receive(:execute).with(merge_request_2)

        subject
      end

      context 'when refresh service 1 returns error status' do
        let(:refresh_service_1_result) { { status: :error, message: 'Failed to create ref' } }

        it 'specifies require_recreate to refresh service 2' do
          expect(MergeTrains::RefreshMergeRequestService)
            .to receive(:new).with(project, maintainer_2, require_recreate: true) { refresh_service_2 }

          subject
        end
      end

      context 'when refresh service 1 returns success status and did not create a pipeline' do
        let(:refresh_service_1_result) { { status: :success, pipeline_created: false } }

        it 'does not specify require_recreate to refresh service 2' do
          expect(MergeTrains::RefreshMergeRequestService)
            .to receive(:new).with(project, maintainer_2, require_recreate: false) { refresh_service_2 }

          subject
        end
      end

      context 'when refresh service 1 returns success status and created a pipeline' do
        let(:refresh_service_1_result) { { status: :success, pipeline_created: true } }

        it 'specifies require_recreate to refresh service 2' do
          expect(MergeTrains::RefreshMergeRequestService)
            .to receive(:new).with(project, maintainer_2, require_recreate: true) { refresh_service_2 }

          subject
        end
      end

      context 'when merge request 1 is not on a merge train' do
        let(:merge_request) { merge_request_1 }
        let!(:merge_request_1) { create(:merge_request) }

        it 'does not refresh' do
          expect(refresh_service_1).not_to receive(:execute).with(merge_request_1)

          subject
        end
      end

      context 'when merge request 1 was on a merge train' do
        before do
          allow(merge_request_1.merge_train_car).to receive(:cleanup_ref)
          merge_request_1.merge_train_car.update_column(
            :status,
            MergeTrains::Car.state_machines[:status].states[:merged].value
          )
        end

        it 'does not refresh' do
          expect(refresh_service_1).not_to receive(:execute).with(merge_request_1)

          subject
        end
      end
    end

    context 'when merge request 2 is passed' do
      let(:merge_request) { merge_request_2 }

      it 'executes RefreshMergeRequestService to all the merge requests from beginning' do
        expect(refresh_service_1).to receive(:execute).with(merge_request_1)
        expect(refresh_service_2).to receive(:execute).with(merge_request_2)

        subject
      end
    end
  end
end
