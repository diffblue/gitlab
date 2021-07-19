# frozen_string_literal: true

# Representation of additional CI Minute allocations, either
# purchased via CustomersDot or assigned by an admin (self-managed)
#
# In the case of a purchase, `purchase_xid` represents the unique ID of the
# purchase via CustomersDot/Zuora
module Ci
  module Minutes
    class AdditionalPack < Ci::ApplicationRecord
      self.table_name = 'ci_minutes_additional_packs'

      belongs_to :namespace

      validates :namespace, :number_of_minutes, presence: true
      validates :expires_at, :purchase_xid, presence: true, if: -> { ::Gitlab.com? }
      validates :purchase_xid, length: { maximum: 32 }
      validates :purchase_xid, uniqueness: true, if: -> { ::Gitlab.com? }
    end
  end
end
