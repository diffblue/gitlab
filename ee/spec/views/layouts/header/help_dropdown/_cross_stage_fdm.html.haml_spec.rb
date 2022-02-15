# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'layouts/header/help_dropdown/_cross_stage_fdm.html.haml' do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  let(:have_group?) { true }
  let(:show_cross_stage_fdm?) { true }
  let(:experiment_enabled?) { true }
  let(:variant_assigned) { :candidate }

  before do
    allow(view).to receive(:current_user).and_return(user)

    if experiment_enabled?
      stub_experiments(cross_stage_fdm: variant_assigned)
    end

    if have_group?
      allow(view).to receive(:show_cross_stage_fdm?).with(group).and_return(show_cross_stage_fdm?)
      assign(:group, group)
    end

    render
  end

  shared_examples 'renders the menu' do
    it 'renders the menu item' do
      expect(rendered).to have_css('li[data-track-action="click_link"][data-track-label="cross_stage_fdm"][data-track-experiment="cross_stage_fdm"]')
      expect(rendered).to have_link(s_('InProductMarketing|Discover Premium & Ultimate'), href: group_advanced_features_dashboard_path(group_id: group))
    end
  end

  shared_examples 'renders nothing' do
    it 'does not render the menu item' do
      expect(rendered).to eq('')
    end
  end

  where(
    :have_group?,           # group
    :show_cross_stage_fdm?, # FDM
    :experiment_enabled?,   # XP on
    :variant_assigned,      # variant
    :examples_to_run        # examples
  ) do
    # group | FDM   | XP on | variant     | examples
    true    | true  | true  | :candidate  | 'renders the menu'
    false   | true  | true  | :candidate  | 'renders nothing'
    true    | false | true  | :candidate  | 'renders nothing'
    true    | true  | false | :candidate  | 'renders nothing'
    true    | true  | true  | :control    | 'renders nothing'
  end

  with_them do
    it_behaves_like params[:examples_to_run]
  end
end
