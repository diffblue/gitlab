# frozen_string_literal: true

module Banzai
  module ReferenceParser
    class IterationParser < BaseParser
      self.reference_type = :iteration

      def references_relation
        Iteration
      end

      private

      def can_read_reference?(user, ref_project, _node)
        can?(user, :read_iteration, ref_project)
      end
    end
  end
end
