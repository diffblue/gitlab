# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RequirementsManagement::RequirementPolicy do
  let_it_be(:owner) { create(:user) }
  let_it_be(:admin) { create(:admin) }
  let_it_be(:reporter) { create(:user) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:guest) { create(:user) }
  let_it_be(:project) { create(:project, :public, namespace: owner.namespace) }
  let_it_be(:resource, reload: true) { create(:work_item, :requirement, project: project).requirement }

  before do
    project.add_reporter(reporter)
    project.add_developer(developer)
    project.add_maintainer(maintainer)
    project.add_guest(guest)
  end

  it_behaves_like 'resource with requirement permissions'
end
