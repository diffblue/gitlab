# frozen_string_literal: true

module GroupWikis
  class GitGarbageCollectWorker # rubocop:disable Scalability/IdempotentWorker
    extend ::Gitlab::Utils::Override
    include GitGarbageCollectMethods

    private

    # Used for getting a project/group out of the resource in order to scope a feature flag
    # Can be removed within https://gitlab.com/gitlab-org/gitlab/-/issues/353607
    def container(resource)
      resource.container
    end

    override :find_resource
    def find_resource(id)
      Group.find(id).wiki
    end
  end
end
