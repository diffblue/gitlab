# frozen_string_literal: true

module Dast
  class ProfileSchedulePolicy < BasePolicy
    delegate { @subject.project }
  end
end
