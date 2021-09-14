# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dast::ProfileSchedulePolicy do
  it_behaves_like 'a dast on-demand scan policy' do
    let_it_be(:record) { create(:dast_profile_schedule, project: project) }
  end
end
