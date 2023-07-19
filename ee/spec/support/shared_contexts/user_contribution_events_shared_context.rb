# frozen_string_literal: true

# See https://docs.gitlab.com/ee/user/profile/contributions_calendar.html#user-contribution-events
RSpec.shared_context '[EE] with user contribution events' do # rubocop:disable RSpec/ContextWording
  include_context 'with user contribution events'

  # targets
  let_it_be(:epic) { create(:epic, group: group, author: user) }

  # work items
  let_it_be(:test_case) { create(:work_item, :test_case, author: user, project: project) }
  let_it_be(:requirement) { create(:work_item, :requirement, author: user, project: project) }
  let_it_be(:objective) { create(:work_item, :objective, author: user, project: project) }
  let_it_be(:key_result) { create(:work_item, :key_result, author: user, project: project) }

  # events

  # closed
  let_it_be(:closed_epic_event) { create(:event, :closed, author: user, project: nil, group: group, target: epic) }
  let_it_be(:closed_test_case_event) { create(:event, :closed, author: user, project: project, target: test_case) }

  # created
  let_it_be(:created_epic_event) { create(:event, :created, author: user, project: nil, group: group, target: epic) }

  let_it_be(:created_test_case_event) do
    create(:event, :created, :for_work_item, author: user, project: project, target: test_case)
  end

  let_it_be(:created_requirement_event) do
    create(:event, :created, :for_work_item, author: user, project: project, target: requirement)
  end

  let_it_be(:created_objective_event) do
    create(:event, :created, :for_work_item, author: user, project: project, target: objective)
  end

  let_it_be(:created_key_result_event) do
    create(:event, :created, :for_work_item, author: user, project: project, target: key_result)
  end

  # reopened
  let_it_be(:reopened_epic_event) { create(:event, :reopened, author: user, project: nil, group: group, target: epic) }
  let_it_be(:reopened_test_case_event) { create(:event, :reopened, author: user, project: project, target: test_case) }
end
