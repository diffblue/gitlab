# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Wikis::CreateAttachmentService, feature_category: :wiki do
  include WikiHelpers

  before do
    stub_group_wikis(true)
  end

  it_behaves_like 'Wikis::CreateAttachmentService#execute', :group
end
