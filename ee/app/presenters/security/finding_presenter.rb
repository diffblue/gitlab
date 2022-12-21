# frozen_string_literal: true

module Security
  class FindingPresenter < Vulnerabilities::FindingPresenter
    presents ::Security::Finding, as: :finding
  end
end
