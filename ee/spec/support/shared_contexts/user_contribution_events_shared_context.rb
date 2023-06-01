# frozen_string_literal: true

# See https://docs.gitlab.com/ee/user/profile/contributions_calendar.html#user-contribution-events
RSpec.shared_context '[EE] with user contribution events' do # rubocop:disable RSpec/ContextWording
  include_context 'with user contribution events'

  # targets
  let_it_be(:epic) { create(:epic, group: group, author: user) }

  # events

  # closed
  let_it_be(:closed_epic_event) { create(:event, :closed, author: user, project: nil, group: group, target: epic) }

  # created
  let_it_be(:created_epic_event) { create(:event, :created, author: user, project: nil, group: group, target: epic) }

  # reopened
  let_it_be(:reopened_epic_event) { create(:event, :reopened, author: user, project: nil, group: group, target: epic) }
end
