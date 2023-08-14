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
    context 'when Gitaly returns a non-ASCII characters in the error message' do
      let(:gitaly_error) { (+"ツ").force_encoding(Encoding::ASCII_8BIT) }
      let(:gitaly_error_in_utf8) { "ツ" }

      it 'returns an error message in UTF-8 encoding' do
        allow(service).to receive(:create_commit!).and_raise(Gitlab::Git::CommandError, gitaly_error)

        result = service.execute

        expect(result[:status]).to be(:error)
        expect(result[:message]).to eq(gitaly_error_in_utf8)
      end

      context 'when feature flag "errors_utf_8_encoding" is disabled' do
        before do
          stub_feature_flags(errors_utf_8_encoding: false)
        end

        it 'returns an error message in original encoding' do
          allow(service).to receive(:create_commit!).and_raise(Gitlab::Git::CommandError, gitaly_error)

          result = service.execute

          expect(result[:status]).to be(:error)
          expect(result[:message]).to eq(gitaly_error)
        end
      end
    end

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
          'repository has exceeded its size limit of 1 B by 1 B'
        )
      end
    end

    context 'when the namespace storage limit has been exceeded', :saas do
      let(:size_checker) { Namespaces::Storage::RootSize.new(group) }

      before do
        create(:gitlab_subscription, :ultimate, namespace: group)
        create(:namespace_root_storage_statistics, namespace: group)
        enforce_namespace_storage_limit(group)
        set_enforcement_limit(group, megabytes: 1)
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
