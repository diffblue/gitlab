# frozen_string_literal: true

module RepositoryStorageHelpers
  def stub_over_repository_limit(namespace)
    stub_feature_flags(namespace_storage_limit: false)
    allow(namespace.root_ancestor).to receive(:contains_locked_projects?).and_return(true)
    allow(namespace.root_ancestor).to receive(:repository_size_excess_project_count).and_return(5)
    allow(namespace.root_ancestor).to receive(:actual_size_limit).and_return(10)
    allow_next_instance_of(Namespaces::Storage::RootExcessSize) do |root_storage_size|
      allow(root_storage_size).to receive(:above_size_limit?).and_return(true)
      allow(root_storage_size).to receive(:usage_ratio).and_return(5.5).at_least(:once)
      allow(root_storage_size).to receive(:current_size).and_return(55)
      allow(root_storage_size).to receive(:limit).and_return(10)
    end
  end
end
