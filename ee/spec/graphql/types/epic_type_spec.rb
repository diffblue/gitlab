# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Epic'] do
  let(:fields) do
    %i[
      id iid title titleHtml description descriptionHtml confidential state group
      parent author labels start_date start_date_is_fixed start_date_fixed
      start_date_from_milestones start_date_from_inherited_source due_date
      due_date_is_fixed due_date_fixed due_date_from_milestones due_date_from_inherited_source
      closed_at created_at updated_at children has_children has_issues
      has_parent web_path web_url relation_path reference issues user_permissions
      notes discussions relative_position subscribed participants
      descendant_counts descendant_weight_sum upvotes downvotes
      user_notes_count user_discussions_count health_status current_user_todos
      award_emoji events ancestors color text_color
    ]
  end

  it { expect(described_class.interfaces).to include(Types::CurrentUserTodos) }

  it { expect(described_class.interfaces).to include(Types::TodoableInterface) }

  it { expect(described_class).to expose_permissions_using(Types::PermissionTypes::Epic) }

  it { expect(described_class.graphql_name).to eq('Epic') }

  it { expect(described_class).to require_graphql_authorizations(:read_epic) }

  it { expect(described_class).to have_graphql_fields(fields) }

  it { expect(described_class).to have_graphql_field(:subscribed, complexity: 5) }

  it { expect(described_class).to have_graphql_field(:participants, complexity: 5) }

  it { expect(described_class).to have_graphql_field(:award_emoji) }
end
