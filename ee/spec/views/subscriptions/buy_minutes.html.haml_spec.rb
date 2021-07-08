# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'subscriptions/buy_minutes' do
  it_behaves_like 'addon form data', '#js-buy-minutes'
end
