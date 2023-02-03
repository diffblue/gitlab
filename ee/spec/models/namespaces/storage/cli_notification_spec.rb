# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::Storage::CliNotification, feature_category: :subscription_cost_management do
  include RepositoryStorageHelpers

  let_it_be(:group, refind: true) { create(:group) }
  let_it_be(:owner) { create(:user) }

  before_all do
    group.add_owner(owner)
  end

  before do
    stub_ee_application_setting(should_check_namespace_plan: true)
    stub_ee_application_setting(enforce_namespace_storage_limit: true)
    stub_ee_application_setting(automatic_purchased_storage_allocation: true)
  end

  describe '#show?' do
    using RSpec::Parameterized::TableSyntax
    subject(:show) { described_class.new(group, owner).show? }

    context 'for namespace limits' do
      where(:current_size, :limit, :expected_value) do
        50  | 100  | false
        80  | 100  | false
        98  | 100  | true
        120 | 100  | false
      end

      with_them do
        before do
          allow_next_instance_of(Namespaces::Storage::RootSize) do |root_storage_size|
            allow(root_storage_size).to receive(:current_size).and_return(current_size)
            allow(root_storage_size).to receive(:limit).and_return(limit)
          end
        end

        it 'returns the expected values' do
          expect(show).to eq(expected_value)
        end
      end
    end

    context 'for repository limits' do
      where(:current_size, :limit, :expected_value) do
        50  | 100 | false
        80  | 100 | true
        98  | 100 | true
        120 | 100 | true
      end

      with_them do
        before do
          stub_feature_flags(namespace_storage_limit: false)
          allow(group.root_ancestor).to receive(:contains_locked_projects?).and_return(true)
          allow_next_instance_of(Namespaces::Storage::RootExcessSize) do |root_storage_size|
            allow(root_storage_size).to receive(:current_size).and_return(current_size)
            allow(root_storage_size).to receive(:limit).and_return(limit)
          end
        end

        it 'returns the expected values' do
          expect(show).to eq(expected_value)
        end
      end
    end
  end

  describe '#payload' do
    subject { described_class.new(group, owner).payload }

    context 'when enforcement_type is a namespace enforcement' do
      before do
        expect_next_instance_of(Namespaces::Storage::RootSize) do |root_storage_size|
          allow(root_storage_size).to receive(:current_size).and_return(11.5)
          allow(root_storage_size).to receive(:limit).and_return(12)
        end
      end

      it 'returns warning messages' do
        expected_message = "##### WARNING #####\nYou have used 96% of the storage quota for #{group.name} " \
                           "(11 Bytes of 12 Bytes).\nIf #{group.name} exceeds the storage quota, " \
                           "all projects in the namespace will be locked and actions will be restricted. " \
                           "To manage storage, or purchase additional storage, " \
                           "see #{::Gitlab::Routing.url_helpers.help_page_url('user/usage_quotas',
                             anchor: 'manage-your-storage-usage')}. " \
                           "To learn more about restricted actions, " \
                           "see #{::Gitlab::Routing.url_helpers.help_page_url('user/read_only_namespaces',
                             anchor: 'restricted-actions')}"

        expect(subject).to eq(expected_message)
      end
    end

    context 'when enforcement_type is a repository enforcement' do
      let(:contains_locked_projects) { true }

      context 'with repository usage' do
        before do
          stub_over_repository_limit(group, contains_locked_projects)
        end

        context 'when additional_purchased_storage_size is 0' do
          it 'returns error message' do
            expect(subject).to eq("##### ERROR #####\nYou have reached the free storage limit of 10 Bytes " \
                                  "on one or more projects.\nPlease purchase additional storage to unlock " \
                                  "your projects over the free 10 Bytes project limit. " \
                                  "You can't push to your repository, create pipelines, " \
                                  "create issues or add comments. To reduce storage capacity, " \
                                  "delete unused repositories, artifacts, wikis, issues, and pipelines.")
          end
        end

        context 'when additional_purchased_storage_size exists' do
          before do
            allow(group.root_ancestor).to receive(:additional_purchased_storage_size).and_return(2)
          end

          it 'returns error message' do
            expect(subject).to eq("##### ERROR #####\n#{group.name} contains 5 locked projects.\n" \
                                  "You have consumed all of your additional storage, please purchase more " \
                                  "to unlock your projects over the free 10 Bytes limit. " \
                                  "You can't push to your repository, create pipelines, " \
                                  "create issues or add comments. To reduce storage capacity, " \
                                  "delete unused repositories, artifacts, wikis, issues, and pipelines.")
          end

          context 'when under size limit' do
            before do
              allow_next_instance_of(Namespaces::Storage::RootExcessSize) do |root_storage_size|
                allow(root_storage_size).to receive(:above_size_limit?).and_return(false)
              end
            end

            it 'returns alert message' do
              expect(subject).to include('If you reach 100% storage capacity, you will not be able to:')
            end
          end
        end

        context 'when namespace does not have locked projects' do
          let(:contains_locked_projects) { false }

          it 'returns the namespace message' do
            expect(subject).to eq("##### ERROR #####\nYou have used 550% of the storage quota for #{group.name} " \
                                  "(55 Bytes of 10 Bytes).\nPlease purchase additional storage " \
                                  "to unlock your projects over the free 10 Bytes project limit. " \
                                  "You can't push to your repository, create pipelines, " \
                                  "create issues or add comments. " \
                                  "To reduce storage capacity, delete unused repositories, " \
                                  "artifacts, wikis, issues, and pipelines.")
          end
        end
      end
    end
  end
end
