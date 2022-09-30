# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting unprotect access levels for a branch protection' do
  include_examples 'perform graphql requests for AccessLevel type objects', :unprotect do
    include_examples 'AccessLevel type objects contains user and group', :unprotect
  end
end
