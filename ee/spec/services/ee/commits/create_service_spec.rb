# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Commits::CreateService, feature_category: :source_code_management do
  include NamespaceStorageHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project, refind: true) { create(:project, group: group) }

  before do
    project.add_maintainer(user)
  end

  subject(:service) do
    described_class.new(project, user, start_branch: 'master', branch_name: 'master')
  end

  describe '#execute' do
    context 'when the repository size limit has been exceeded' do
      before do
        stub_licensed_features(repository_size_limit: true)
        project.update!(repository_size_limit: 1)
        allow(project.repository_size_checker).to receive(:current_size).and_return(2)
      end

      it 'raises an error' do
        expect(Gitlab::ErrorTracking).to receive(:log_exception)
          .with(instance_of(Commits::CreateService::ValidationError)).and_call_original

        result = service.execute

        expect(result[:status]).to be(:error)
        expect(result[:message]).to eq(
          'Your changes could not be committed, because this ' \
          'repository has exceeded its size limit of 1 Byte by 1 Byte'
        )
      end
    end

    context 'when the namespace storage limit has been exceeded', :saas do
      let(:size_checker) { Namespaces::Storage::RootSize.new(group) }

      before do
        create(:gitlab_subscription, :ultimate, namespace: group)
        create(:namespace_root_storage_statistics, namespace: group)
        enforce_namespace_storage_limit(group)
        set_storage_size_limit(group, megabytes: 1)
        set_used_storage(group, megabytes: 2)
      end

      it 'raises an error' do
        expect(Gitlab::ErrorTracking).to receive(:log_exception)
          .with(instance_of(Commits::CreateService::ValidationError)).and_call_original

        result = service.execute

        expect(result[:status]).to be(:error)
        expect(result[:message]).to eq(size_checker.error_message.commit_error)
      end

      context 'with a subgroup project' do
        let(:subgroup) { create(:group, parent: group) }
        let(:project) { create(:project, group: subgroup) }

        it 'raises an error' do
          expect(Gitlab::ErrorTracking).to receive(:log_exception)
            .with(instance_of(Commits::CreateService::ValidationError)).and_call_original

          result = service.execute

          expect(result[:status]).to be(:error)
          expect(result[:message]).to eq(size_checker.error_message.commit_error)
        end
      end
    end

    context 'when the namespace is over the free user cap limit', :saas do
      let_it_be(:group) do
        create(:group_with_plan, :private, :with_root_storage_statistics, plan: :free_plan).tap do |record|
          project.update!(group: record)
        end
      end

      before do
        stub_ee_application_setting(dashboard_limit_enabled: true)
      end

      it 'raises an error' do
        expect(Gitlab::ErrorTracking).to receive(:log_exception)
                                           .with(instance_of(Commits::CreateService::ValidationError)).and_call_original

        result = service.execute

        expect(result[:status]).to be(:error)
        expect(result[:message]).to match(/Your top-level group is over the user limit/)
      end
    end
  end
end
