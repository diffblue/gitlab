# frozen_string_literal: true

module GroupWikis
  class GitGarbageCollectWorker # rubocop:disable Scalability/IdempotentWorker
    extend ::Gitlab::Utils::Override
    include GitGarbageCollectMethods

    private

    override :find_resource
    def find_resource(id)
      Group.find(id).wiki
    end
  end
end
