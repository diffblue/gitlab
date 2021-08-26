# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'subscriptions/buy_storage' do
  it_behaves_like 'buy storage addon form data', '#js-buy-storage'
end
