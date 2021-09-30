# frozen_string_literal: true

module EE
  module Issuables
    module LabelFilter
      extend ::Gitlab::Utils::Override

      SCOPED_LABEL_WILDCARD = '*'

      private

      override :find_label_ids_uncached
      def find_label_ids_uncached(label_names)
        return super unless root_namespace.licensed_feature_available?(:scoped_labels)

        scoped_label_wildcards, label_names = extract_scoped_label_wildcards(label_names)

        find_wildcard_label_ids(scoped_label_wildcards) + super(label_names)
      end

      def extract_scoped_label_wildcards(label_names)
        label_names.partition { |name| name.ends_with?(::Label::SCOPED_LABEL_SEPARATOR + SCOPED_LABEL_WILDCARD) }
      end

      # This is similar to the CE version of `#find_label_ids_uncached` but the results
      # are grouped by the wildcard prefix. With nested scoped labels, a label can match multiple prefixes.
      # So a label_id can be present multiple times.
      #
      # For example, if we pass in `['workflow::*', 'workflow::backend::*']`, this will return something like:
      # `[ [1, 2, 3], [1, 2] ]`
      #
      # rubocop: disable CodeReuse/ActiveRecord
      def find_wildcard_label_ids(scoped_label_wildcards)
        return [] if scoped_label_wildcards.empty?

        scoped_label_prefixes = scoped_label_wildcards.map { |w| w.delete_suffix(SCOPED_LABEL_WILDCARD) }

        relations = scoped_label_prefixes.flat_map do |prefix|
          search_term = prefix + '%'

          [
            group_labels_for_root_namespace.where('title LIKE ?', search_term),
            project_labels_for_root_namespace.where('title LIKE ?', search_term)
          ]
        end

        labels = ::Label
          .from_union(relations, remove_duplicates: false)
          .reorder(nil)
          .pluck(:title, :id)

        group_by_prefix(labels, scoped_label_prefixes).values
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def group_by_prefix(labels, prefixes)
        labels.each_with_object({}) do |(title, id), ids_by_prefix|
          prefixes.each do |prefix|
            next unless title.start_with?(prefix)

            ids_by_prefix[prefix] ||= []
            ids_by_prefix[prefix] << id
          end
        end
      end
    end
  end
end
