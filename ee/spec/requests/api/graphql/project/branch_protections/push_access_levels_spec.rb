# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting push access levels for a branch protection' do
  include_examples 'perform graphql requests for AccessLevel type objects', :push do
    include_examples 'AccessLevel type objects contains user and group', :push
  end
end
