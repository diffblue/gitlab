# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Search::Panel, feature_category: :navigation do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:user) { create(:user) }

  let(:context) { Sidebars::Context.new(current_user: current_user, container: user) }
  let(:panel) { described_class.new(context) }

  subject { described_class.new(context) }

  it_behaves_like 'a panel with uniquely identifiable menu items'
  it_behaves_like 'a panel without placeholders'
end
