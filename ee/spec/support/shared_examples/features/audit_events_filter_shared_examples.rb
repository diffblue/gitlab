# frozen_string_literal: true

RSpec.shared_examples_for 'audit events date filter' do
  it 'shows only 2 days old events' do
    visit method(events_path).call(entity, created_after: 4.days.ago.to_date, created_before: 2.days.ago.to_date)

    find('.audit-log-table td', match: :first)

    expect(page).not_to have_content(audit_event_1.present.date)
    expect(page).to have_content(audit_event_2.present.date)
    expect(page).not_to have_content(audit_event_3.present.date)
  end

  it 'shows only today\'s event' do
    visit method(events_path).call(entity, created_after: 1.day.ago.to_date, created_before: Date.current.to_date)

    find('.audit-log-table td', match: :first)

    expect(page).not_to have_content(audit_event_1.present.date)
    expect(page).not_to have_content(audit_event_2.present.date)
    expect(page).to have_content(audit_event_3.present.date)
  end

  it 'shows a message if provided date is invalid' do
    visit method(events_path).call(entity, created_after: '12-345-6789')

    expect(page).to have_content('Invalid date format. Please use UTC format as YYYY-MM-DD')
  end
end

RSpec.shared_examples_for 'audit events author filtering without entity admin permission' do
  it 'shows only events by the current user when filtering for another user\'s id' do
    visit method(events_path).call(entity, author_id: author.id)

    expect(page).to have_content(audit_event_1.present.ip_address)
    expect(page).not_to have_content(audit_event_2.present.ip_address)
  end

  it 'shows only events by the current user when filtering for another user\'s username' do
    visit method(events_path).call(entity, author_username: author.username)

    expect(page).to have_content(audit_event_1.present.ip_address)
    expect(page).not_to have_content(audit_event_2.present.ip_address)
  end
end
