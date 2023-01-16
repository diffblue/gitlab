# frozen_string_literal: true

module Dast
  class PreScanVerificationPolicy < BasePolicy
    delegate { @subject.dast_profile }
  end
end
