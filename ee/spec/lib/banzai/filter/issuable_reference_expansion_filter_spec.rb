# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Banzai::Filter::IssuableReferenceExpansionFilter do
  include FilterSpecHelper

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:other_group) { create(:group) }
  let_it_be(:epic) { create(:epic, :opened, group: group, title: 'Some epic') }
  let_it_be(:closed_epic) { create(:epic, :closed, group: group) }

  let_it_be(:context) { { current_user: user, issuable_reference_expansion_enabled: true, group: group } }

  def create_link(text, data)
    ActionController::Base.helpers.link_to(text, '', class: 'gfm has-tooltip', data: data)
  end

  it 'ignores open epic references' do
    link = create_link(epic.to_reference, epic: epic.id, reference_type: 'epic')

    doc = filter(link, context)

    expect(doc.css('a').last.text).to eq(epic.to_reference)
  end

  it 'appends state to closed epic references' do
    link = create_link(closed_epic.to_reference, epic: closed_epic.id, reference_type: 'epic')

    doc = filter(link, context)

    expect(doc.css('a').last.text).to eq("#{closed_epic.to_reference} (closed)")
  end

  it 'skips cross references if the user cannot read cross group' do
    expect(Ability).to receive(:allowed?).with(user, :read_cross_project) { false }

    link = create_link(closed_epic.to_reference(other_group), epic: closed_epic.id, reference_type: 'epic')

    doc = filter(link, context.merge(group: other_group))

    expect(doc.css('a').last.text).to eq("#{closed_epic.to_reference(other_group)}")
  end

  it 'shows title for references with +' do
    link = create_link(epic.to_reference, epic: epic.id, reference_type: 'epic', reference_format: '+')

    doc = filter(link, context)

    expect(doc.css('a').last.text).to eq("#{epic.title} (#{epic.to_reference})")
  end
end
