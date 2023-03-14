# frozen_string_literal: true

module Security
  class DashboardController < ::Security::ApplicationController
    layout 'instance_security'
  end
end

Security::DashboardController.prepend_mod
