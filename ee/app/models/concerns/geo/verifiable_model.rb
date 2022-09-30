# frozen_string_literal: true

module Geo
  # This concern is included on Model classes (as opposed to Registry classes)
  # to manage their verification states. Note that this concern does not handle
  # how verification is performed; see `VerifiableReplicator`.
  #
  # It handles both cases where verification state is stored in a separate
  # table or when it is stored in the same table as the model.

  module VerifiableModel
    extend ActiveSupport::Concern
    include ::Geo::VerificationState

    included do
      def save_verification_details
        return unless self.class.separate_verification_state_table?

        return unless in_verifiables?

        # During a transaction, `verification_state_object` could be built before
        # a value for `verification_state_model_key` exists. So we check for that
        # before saving the `verification_state_object`
        unless verification_state_object.persisted?
          verification_state_object[self.class.verification_state_model_key] = self.id
        end

        verification_state_object.save!
      end

      def in_verifiables?
        # This query could be simpler, but this way it always uses the best index: the primary key index.
        cte = Gitlab::SQL::CTE.new(:verifiables, self.class.primary_key_in(self))
        verifiables = self.class.with(cte.to_arel).from(cte.alias_to(self.class.arel_table)).verifiables

        verifiables.exists?
      end

      # Implement this method in the class that includes this concern to specify
      # a different ActiveRecord association name that stores the verification state
      # See module EE::MergeRequestDiff for example
      def verification_state_object
        raise NotImplementedError if self.class.separate_verification_state_table?

        self
      end
    end

    class_methods do
      include Delay

      def pluck_verification_details_ids_in_range(range)
        verification_state_table_class
          .where(self.verification_state_model_key => range)
          .pluck(self.verification_state_model_key)
      end

      def pluck_verifiable_ids_in_range(range)
        self
          .verifiables
          .primary_key_in(range)
          .pluck_primary_key
      end
    end
  end
end
