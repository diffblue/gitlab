# frozen_string_literal: true

module Namespaces
  class CheckExcessStorageSizeService < CheckStorageSizeService
    def initialize(namespace, user)
      super
      @root_storage_size = EE::Namespace::RootExcessStorageSize.new(root_namespace)
    end

    private

    def enforce_limit?
      root_storage_size.enforce_limit?
    end

    def usage_message
      if root_namespace.contains_locked_projects?
        params = { namespace_name: root_namespace.name,
                  locked_project_count: root_namespace.repository_size_excess_project_count,
                  free_size_limit: formatted(root_namespace.actual_size_limit) }

        if root_namespace.additional_purchased_storage_size == 0
          s_("NamespaceStorageSize|You have reached the free storage limit of %{free_size_limit} on one or more projects." % params)
        else
          ns_("NamespaceStorageSize|%{namespace_name} contains %{locked_project_count} locked project", "NamespaceStorageSize|%{namespace_name} contains %{locked_project_count} locked projects", params[:locked_project_count]) % params
        end
      else
        s_("NamespaceStorageSize|You have reached %{usage_in_percent} of %{namespace_name}'s storage capacity (%{used_storage} of %{storage_limit})" % current_usage_params)
      end
    end

    def above_size_limit_message
      if root_namespace.additional_purchased_storage_size > 0
        s_("NamespaceStorageSize|You have consumed all of your additional storage, please purchase more to unlock your projects over the free %{free_size_limit} limit. You can't %{base_message}" % { base_message: base_message, free_size_limit: formatted(root_namespace.actual_size_limit) })
      else
        s_("NamespaceStorageSize|Please purchase additional storage to unlock your projects over the free %{free_size_limit} project limit. You can't %{base_message}" % { base_message: base_message, free_size_limit: formatted(root_namespace.actual_size_limit) })
      end
    end

    def formatted(number)
      number_to_human_size(number, delimiter: ',', precision: 2)
    end
  end
end
