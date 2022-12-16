# frozen_string_literal: true

# Checks visibility of monitor features.
#
# params:
# - policy [Symbol] - the subject under test
# - allow_lowest_role [Symbol] - All roles lower than this are not allowed.
#   All higher roles including this role are allowed.
RSpec.shared_examples 'monitor feature visibility' do |allow_lowest_role:|
  using RSpec::Parameterized::TableSyntax

  available_roles = %i[anonymous non_member guest reporter developer maintainer owner]

  let(:role_allowed) { allow_lowest_role }
  let(:role_disallowed) { available_roles[available_roles.index(allow_lowest_role) - 1] }

  where(:project_visibility, :access_level, :role, :allowed) do
    :public   | ProjectFeature::ENABLED  | ref(:role_allowed)    | true
    :public   | ProjectFeature::ENABLED  | ref(:role_disallowed) | false
    :public   | ProjectFeature::PRIVATE  | ref(:role_allowed)    | true
    :public   | ProjectFeature::PRIVATE  | ref(:role_disallowed) | false
    :public   | ProjectFeature::DISABLED | ref(:role_allowed)    | false
    :public   | ProjectFeature::DISABLED | ref(:role_disallowed) | false
    :internal | ProjectFeature::ENABLED  | ref(:role_allowed)    | true
    :internal | ProjectFeature::ENABLED  | ref(:role_disallowed) | false
    :internal | ProjectFeature::PRIVATE  | ref(:role_allowed)    | true
    :internal | ProjectFeature::PRIVATE  | ref(:role_disallowed) | false
    :internal | ProjectFeature::DISABLED | ref(:role_allowed)    | false
    :internal | ProjectFeature::DISABLED | ref(:role_disallowed) | false
    :private  | ProjectFeature::ENABLED  | ref(:role_allowed)    | true
    :private  | ProjectFeature::ENABLED  | ref(:role_disallowed) | false
    :private  | ProjectFeature::PRIVATE  | ref(:role_allowed)    | true
    :private  | ProjectFeature::PRIVATE  | ref(:role_disallowed) | false
    :private  | ProjectFeature::DISABLED | ref(:role_allowed)    | false
    :private  | ProjectFeature::DISABLED | ref(:role_disallowed) | false
  end

  with_them do
    let(:project) { public_send("#{project_visibility}_project") }

    before do
      project.project_feature.update!(monitor_access_level: access_level)
    end

    it { is_expected.to(allowed ? be_allowed(policy) : be_disallowed(policy)) }
  end
end
