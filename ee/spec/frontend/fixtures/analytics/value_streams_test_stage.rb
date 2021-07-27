# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'Analytics, Value streams: test stage (JavaScript fixtures)', :sidekiq_inline do
  describe Groups::Analytics::CycleAnalytics::StagesController, type: :controller do
    include_context '[EE] Analytics fixtures shared context'

    render_views

    include_examples 'Analytics > Value stream fixtures', 'test'
  end
end
