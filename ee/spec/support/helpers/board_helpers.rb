# frozen_string_literal: true
module BoardHelpers
  def load_epic_swimlanes
    page.find_button(s_('None')).click
    page.find('li[role="option"]', text: s_('Epic')).click

    wait_for_requests
  end

  def load_unassigned_issues
    page.find("[data-testid='unassigned-lane-toggle']").click

    wait_for_requests
  end
end
