# frozen_string_literal: true

module EE
  module RemoteMirror
    extend ActiveSupport::Concern

    prepended do
      include MirrorConfiguration

      validates :mirror_branch_regex, absence: true, if: -> { only_protected_branches? }
      validates :mirror_branch_regex, untrusted_regexp: true, length: { maximum: 255 }
    end

    def sync?
      super && !::Gitlab::Geo.secondary?
    end

    def only_mirror_protected_branches_column
      only_protected_branches
    end

    def options_for_update
      options = super
      options[:only_branches_matching] = branches_to_sync if mirror_branch_regex.present?

      options
    end

    def branches_to_sync
      branch_filter = ::Gitlab::UntrustedRegexp.new(mirror_branch_regex)

      project.repository.branch_names.select do |branch_name|
        branch_filter.match?(branch_name)
      end
    end
  end
end
