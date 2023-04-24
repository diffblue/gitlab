# frozen_string_literal: true

require 'spec_helper'

RSpec.describe '[EE] Update of user activity', feature_category: :user_profile do
  paths_to_visit = [
    '/group/project/-/integrations/jira/issues'
  ]

  it_behaves_like 'updating of user activity', paths_to_visit
end
