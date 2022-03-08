# frozen_string_literal: true

module Registrations
  class CompanyController < ApplicationController
    include Registrations::CreateGroup
    include Registrations::ApplyTrial
    include ::Gitlab::Utils::StrongMemoize
    include OneTrustCSP

    layout 'minimal'

    feature_category :onboarding

    def new
    end
  end
end
