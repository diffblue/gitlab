# frozen_string_literal: true

RSpec.shared_examples 'assigning an already assigned user' do |is_multiline|
  before do
    target.assignees = [assignee]
  end

  it 'adds multiple assignees from the list' do
    _, update_params, message = service.execute(note)

    expected_format = is_multiline ? /Assigned @\w+. Assigned @\w+./ : /Assigned @\w+ and @\w+./

    expect(message).to match(expected_format)
    expect(message).to include("@#{assignee.username}")
    expect(message).to include("@#{user.username}")

    expect { service.apply_updates(update_params, note) }.not_to raise_error
  end
end
