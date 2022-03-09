# frozen_string_literal: true

module Registrations
  class CompanyController < ApplicationController
    layout 'minimal'

    before_action :check_if_gl_com_or_dev
    feature_category :onboarding

    def new
    end
  end
end
