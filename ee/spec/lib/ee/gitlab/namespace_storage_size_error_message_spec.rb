# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::Gitlab::NamespaceStorageSizeErrorMessage, :saas do
  include NamespaceStorageHelpers

  let_it_be(:namespace) { create(:namespace_with_plan, plan: :ultimate_plan) }
  let_it_be(:root_storage_statistics) { create(:namespace_root_storage_statistics, namespace: namespace) }

  let(:size_checker) { EE::Namespace::RootStorageSize.new(namespace) }
  let(:error_message) { described_class.new(size_checker) }

  before do
    set_storage_size_limit(namespace, megabytes: 10)
    set_used_storage(namespace, megabytes: 12)
  end

  describe '#commit_error' do
    it 'returns the expected message' do
      expected_message = "Your push to this repository has been rejected because " \
        "the namespace storage limit of 10 MB has been reached. " \
        "Reduce your namespace storage or purchase additional storage."

      expect(error_message.commit_error).to eq(expected_message)
    end
  end

  describe '#merge_error' do
    it 'returns the expected message' do
      expected_message = "This merge request cannot be merged, because " \
        "the namespace storage limit of 10 MB has been reached."

      expect(error_message.merge_error).to eq(expected_message)
    end
  end

  describe '#push_error' do
    it 'returns the expected message' do
      expected_message = "Your push to this repository has been rejected because " \
        "the namespace storage limit of 10 MB has been reached. " \
        "Reduce your namespace storage or purchase additional storage."

      expect(error_message.push_error).to eq(expected_message)
    end
  end

  describe '#new_changes_error' do
    it 'returns the expected message' do
      expected_message = "Your push to this repository has been rejected because " \
        "it would exceed the namespace storage limit of 10 MB. " \
        "Reduce your namespace storage or purchase additional storage."

      expect(error_message.new_changes_error).to eq(expected_message)
    end
  end

  describe '#above_size_limit_message' do
    it 'returns the expected message' do
      expected_message = "The namespace storage size (12 MB) exceeds the limit of 10 MB " \
        "by 2 MB. You won't be able to push new code to this project. " \
        "Please contact your GitLab administrator for more information."

      expect(error_message.above_size_limit_message).to eq(expected_message)
    end
  end
end
