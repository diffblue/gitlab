# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProtectedTag::CreateAccessLevel, feature_category: :source_code_management do
  include_examples 'ee protected ref access', :protected_tag
end
