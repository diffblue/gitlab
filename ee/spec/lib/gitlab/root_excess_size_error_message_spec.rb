# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::RootExcessSizeErrorMessage, feature_category: :consumables_cost_management do
  let(:namespace) { build(:namespace, additional_purchased_storage_size: limit) }
  let(:checker) { Namespaces::Storage::RootExcessSize.new(namespace) }
  let(:current_size) { 9.megabytes }
  let(:limit) { 10 }
  let(:message_params) do
    {
      size_limit: limit,
      namespace_name: namespace.name
    }
  end

  before do
    allow(namespace).to receive(:total_repository_size_excess).and_return(current_size)
  end

  subject(:message) { described_class.new(checker, message_params) }

  describe '#push_warning' do
    it 'returns the correct message' do
      expect(message.push_warning)
        .to eq(
          <<~MSG.squish
            ##### WARNING ##### You have used 90% of the storage quota for this project
            (9 MiB of 10 MiB). If a project reaches 100% of the storage quota (10 MiB)
            the project will be in a read-only state, and you won't be able to push to your repository or add large files.
            To reduce storage usage, reduce git repository and git LFS storage. For more information about storage limits,
            see our docs: http://localhost/help/user/usage_quotas#project-storage-limit.
          MSG
        )
    end
  end

  describe '#push_error' do
    before do
      stub_ee_application_setting(repository_size_limit: 10.gigabytes)
    end

    it 'returns the correct message' do
      expect(message.push_error)
        .to eq(
          <<~MSG.squish
            You have reached the free storage limit of 10 GiB on one or more projects.
            To unlock your projects over the free 10 GiB project limit, you must purchase
            additional storage. You can't push to your repository, create pipelines, create issues, or add comments.
            To reduce storage capacity, you can delete unused repositories, artifacts, wikis, issues, and pipelines.
          MSG
        )
    end
  end
end
