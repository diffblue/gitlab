# frozen_string_literal: true

module FeatureApprovalHelper
  def open_modal(text: 'Edit', expand: true)
    page.execute_script "document.querySelector('#{config_selector}').scrollIntoView()"

    if expand
      click_button 'Approval rules'
    end

    within(config_selector) do
      click_on(text)
    end
  end

  def remove_approver(name)
    el = page.find("#{modal_selector} .content-list li", text: /#{name}/i)
    el.find('button').click
  end

  def expect_avatar(container, users)
    users = Array(users)

    members = container.all('.js-members img.gl-avatar').map do |member|
      member['alt']
    end

    users.each do |user|
      expect(members).to include(user.name)
    end

    expect(members.size).to eq(users.size)
  end
end
