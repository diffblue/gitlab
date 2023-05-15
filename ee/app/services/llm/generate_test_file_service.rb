# frozen_string_literal: true

module Llm
  class GenerateTestFileService < BaseService
    def valid?
      super &&
        Feature.enabled?(:generate_test_file_flag, user) &&
        resource.resource_parent.root_ancestor.licensed_feature_available?(:generate_test_file) &&
        Gitlab::Llm::StageCheck.available?(resource.resource_parent.root_ancestor, :generate_test_file)
    end

    private

    def perform
      perform_async(user, resource, :generate_test_file, options)
    end
  end
end
