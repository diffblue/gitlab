# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting merge access levels for a branch protection' do
  include_examples 'perform graphql requests for AccessLevel type objects', :merge do
    include_examples 'AccessLevel type objects contains user and group', :merge
  end
end
