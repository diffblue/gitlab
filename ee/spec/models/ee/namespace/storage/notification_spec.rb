# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::Namespace::Storage::Notification do
  include NamespaceStorageHelpers

  let_it_be(:group, refind: true) { create(:group) }
  let_it_be(:owner) { create(:user) }
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:developer) { create(:user) }
  let(:user) { owner }
  let(:alert_level) { :warning }

  describe '#show?' do
    subject { described_class.new(group, user).show? }

    before do
      group.add_owner(owner)
      group.add_maintainer(maintainer)
      group.add_developer(developer)
      stub_ee_application_setting(should_check_namespace_plan: true)
      stub_ee_application_setting(enforce_namespace_storage_limit: true)
      stub_ee_application_setting(automatic_purchased_storage_allocation: true)
      allow_next_instance_of(EE::Namespace::Storage::Notification) do |notification|
        allow(notification).to receive(:alert_level).and_return(alert_level)
      end
    end

    it 'returns true if all conditions are met' do
      is_expected.to be true
    end

    context 'when not SaaS' do
      before do
        stub_ee_application_setting(should_check_namespace_plan: false)
      end

      it { is_expected.to be false }
    end

    context 'when the user is not provided' do
      let(:user) { nil }

      it { is_expected.to be false }
    end

    context 'when the user does not have at least maintainer access to the group' do
      let(:user) { developer }

      it { is_expected.to be false }
    end

    context 'when alert level is none' do
      let(:alert_level) { :none }

      it { is_expected.to be false }
    end

    context 'for repository limits' do
      before do
        stub_feature_flags(namespace_storage_limit: false)
      end

      it 'returns true if all conditions are met' do
        is_expected.to be true
      end

      context 'when the user does not have at least owner access to the group' do
        let(:user) { maintainer }

        it { is_expected.to be false }
      end
    end
  end

  describe '#payload' do
    let(:contains_locked_projects) { true }

    subject { described_class.new(group, user).payload }

    shared_examples 'namespace usage_message' do
      it 'returns correct usage_message' do
        expect(subject[:usage_message])
        .to eq "You have used 550% of the storage quota for #{group.name} (55 Bytes of 10 Bytes)"
      end
    end

    context 'with repository usage' do
      before do
        stub_feature_flags(namespace_storage_limit: false)
        stub_ee_application_setting(automatic_purchased_storage_allocation: true)
        allow(group.root_ancestor).to receive(:contains_locked_projects?).and_return(contains_locked_projects)
        allow(group.root_ancestor).to receive(:repository_size_excess_project_count).and_return(5)
        allow(group.root_ancestor).to receive(:actual_size_limit).and_return(10)
        allow_next_instance_of(Namespaces::Storage::RootExcessSize) do |root_storage_size|
          allow(root_storage_size).to receive(:above_size_limit?).and_return(true)
          allow(root_storage_size).to receive(:usage_ratio).and_return(5.5).at_least(:once)
          allow(root_storage_size).to receive(:current_size).and_return(55)
          allow(root_storage_size).to receive(:limit).and_return(10)
        end
      end

      it 'includes a usage_quotas help link' do
        expect(subject[:explanation_message][:main][:link]).to eq(
          {
            text: "Learn more.",
            href: "/help/user/usage_quotas#manage-your-storage-usage"
          }
        )
      end

      context 'when additional_purchased_storage_size is 0' do
        it 'returns proper usage_message' do
          expect(subject[:usage_message]).to eq "You have reached the free storage limit of " \
                                                "10 Bytes on one or more projects."
        end

        it 'returns proper explanation_message' do
          expect(subject[:explanation_message][:main][:text])
            .to include 'Please purchase additional storage to unlock your projects'
        end
      end

      context 'when additional_purchased_storage_size exists' do
        before do
          allow(group.root_ancestor).to receive(:additional_purchased_storage_size).and_return(2)
        end

        it 'returns usage_message when there is additional_purchased_storage_size' do
          expect(subject[:usage_message]).to eq "#{group.name} contains 5 locked projects"
        end

        it 'returns usage_message with singular version if its just 1 locked project' do
          allow(group.root_ancestor).to receive(:repository_size_excess_project_count).and_return(1)

          expect(subject[:usage_message]).to eq "#{group.name} contains 1 locked project"
        end

        it 'returns explanation_message when there is additional_purchased_storage_size' do
          expect(subject[:explanation_message][:main][:text])
            .to include 'You have consumed all of your additional storage'
        end

        context 'when under size limit' do
          before do
            allow_next_instance_of(Namespaces::Storage::RootExcessSize) do |root_storage_size|
              allow(root_storage_size).to receive(:above_size_limit?).and_return(false)
            end
          end

          it 'returns explanation_message with a warning' do
            expect(subject[:explanation_message][:main][:text])
              .to include 'If you reach 100% storage capacity, you will not be able to:'
          end
        end
      end

      context 'when namespace does not have locked projects' do
        let(:contains_locked_projects) { false }

        it_behaves_like 'namespace usage_message'
      end
    end

    context 'with namespace usage', :saas do
      before do
        enforce_namespace_storage_limit(group)
      end

      context 'when above the limit' do
        before do
          expect_next_instance_of(Namespaces::Storage::RootSize) do |root_storage_size|
            expect(root_storage_size).to receive(:above_size_limit?).and_return(true)
            expect(root_storage_size).to receive(:usage_ratio).and_return(5.5).at_least(:once)
            expect(root_storage_size).to receive(:current_size).and_return(55)
            expect(root_storage_size).to receive(:limit).and_return(10)
          end
        end

        it_behaves_like 'namespace usage_message'

        it 'returns above the limit messages' do
          expect(subject[:explanation_message]).to eq(
            {
              main: {
                text: "#{group.name} is now read-only. " \
                      "Projects under this namespace are locked and actions are restricted.",
                link: {
                  text: "Which actions are restricted?",
                  href: '/help/user/read_only_namespaces'
                }
              },
              footer: {
                text: "Manage your storage usage or, " \
                      "if you are a namespace Owner, purchase additional storage.",
                link: {
                  text: "Learn more.",
                  href: '/help/user/usage_quotas#manage-your-storage-usage'
                }
              }
            }
          )
        end
      end

      context 'when below the limit' do
        before do
          expect_next_instance_of(Namespaces::Storage::RootSize) do |root_storage_size|
            expect(root_storage_size).to receive(:above_size_limit?).and_return(false)
          end
        end

        it 'returns below the limit messages' do
          expect(subject[:explanation_message]).to eq(
            {
              main: {
                text: "If #{group.name} exceeds the storage quota, " \
                      "all projects in the namespace will be locked and actions will be restricted.",
                link: {
                  text: "Which actions become restricted?",
                  href: "/help/user/read_only_namespaces"
                }
              },
              footer: {
                text: "Manage your storage usage or, " \
                      "if you are a namespace Owner, purchase additional storage.",
                link: {
                  text: "Learn more.",
                  href: "/help/user/usage_quotas#manage-your-storage-usage"
                }
              }
            }
          )
        end
      end
    end
  end
end
