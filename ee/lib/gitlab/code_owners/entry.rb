# frozen_string_literal: true

module Gitlab
  module CodeOwners
    class Entry
      include ::Gitlab::Utils::StrongMemoize

      Data = Struct.new(:pattern, :owner_line, :section, :optional, :approvals_required)

      attr_reader :data
      protected :data

      delegate :pattern, :hash, :owner_line, :section, :approvals_required, to: :data

      def initialize(pattern, owner_line, section = Section::DEFAULT, optional = false, approvals_required = 0)
        @data = Data.new(pattern, owner_line, section, optional, approvals_required)
      end

      def all_users
        strong_memoize(:all_users) do
          group_members = groups.flat_map do |group|
            raise "CodeOwners for #{group.full_path} not loaded" unless group.users.loaded?

            group.users
          end

          (group_members + users).uniq
        end
      end

      def users
        raise "CodeOwners for #{owner_line} not loaded" unless defined?(@users)

        @users.to_a
      end

      def groups
        raise "CodeOwners groups for #{owner_line} not loaded" unless defined?(@groups)

        @groups.to_a
      end

      def add_matching_groups_from(new_groups)
        @groups ||= Set.new

        matching_groups = new_groups.select { |u| matching_group?(u) }
        @groups.merge(matching_groups)
      end

      def add_matching_users_from(new_users)
        @users ||= Set.new

        matching_users = new_users.select { |u| matching_user?(u) }
        @users.merge(matching_users)
      end

      def optional?
        data.optional
      end

      def ==(other)
        return false unless other.is_a?(self.class)

        data == other.data
      end
      alias_method :eql?, :==

      private

      def extractor
        @extractor ||= Gitlab::CodeOwners::ReferenceExtractor.new(owner_line)
      end

      def emails
        @emails ||= extractor.emails.map(&:downcase)
      end

      def names
        @names ||= extractor.names.map(&:downcase)
      end

      def matching_group?(group)
        names.include?(group.full_path.downcase)
      end

      def matching_user?(user)
        names.include?(user.username.downcase) || matching_emails?(user)
      end

      def matching_emails?(user)
        raise "Emails not loaded for #{user}" unless user.emails.loaded?

        emails.any? { |email| user.verified_email?(email) }
      end
    end
  end
end
