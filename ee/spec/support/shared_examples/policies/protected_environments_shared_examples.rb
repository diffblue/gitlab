# frozen_string_literal: true

RSpec.shared_examples 'protected environments access' do |developer_access: true, direct_access: false|
  using RSpec::Parameterized::TableSyntax

  include AdminModeHelper

  before do
    allow(License).to receive(:feature_available?).and_call_original
    allow(License).to receive(:feature_available?).with(:protected_environments).and_return(feature_available)
  end

  context 'when Protected Environments feature is not available in the project' do
    let(:feature_available) { false }

    where(:access_level, :result) do
      :guest      | false
      :reporter   | false
      :developer  | developer_access
      :maintainer | true
      :admin      | true
    end

    with_them do
      before do
        environment

        update_user_access(access_level, user, project)
      end

      it { is_expected.to eq(result) }
    end
  end

  context 'when Protected Environments feature is available in the project' do
    let(:feature_available) { true }

    shared_examples_for 'authorize correctly per access type' do
      context 'when user does not have access to the environment' do
        where(:access_level, :result) do
          :guest      | false
          :reporter   | false
          :developer  | false
          :maintainer | false
          :admin      | true
        end

        with_them do
          before do
            protected_environment

            update_user_access(access_level, user, project)
          end

          it { is_expected.to eq(result) }
        end
      end

      context 'when user has access to the environment' do
        where(:access_level, :result) do
          :reporter   | direct_access
          :developer  | developer_access
          :maintainer | true
          :admin      | true
        end

        with_them do
          before do
            protected_environment.deploy_access_levels.create!(user: user)

            update_user_access(access_level, user, project)
          end
          it { is_expected.to eq(result) }
        end
      end

      context 'when the user has access via a group' do
        let(:operator_group) { create(:group) }

        before do
          project.add_reporter(user)
          operator_group.add_reporter(user)

          protected_environment.deploy_access_levels.create!(group: operator_group)
        end

        it { is_expected.to eq(direct_access) }
      end
    end

    context 'when environment is protected with project-level protection' do
      let(:protected_environment) { create(:protected_environment, :project_level, name: environment.name, project: project) }

      it_behaves_like 'authorize correctly per access type'
    end

    context 'when environment is protected with group-level protection' do
      let(:protected_environment) { create(:protected_environment, :group_level, name: environment.tier, group: group) }

      it_behaves_like 'authorize correctly per access type'
    end

    context 'when environment is not protected' do
      where(:access_level, :result) do
        :guest      | false
        :reporter   | false
        :developer  | developer_access
        :maintainer | true
        :admin      | true
      end

      with_them do
        before do
          update_user_access(access_level, user, project)
        end

        it { is_expected.to eq(result) }
      end
    end
  end

  def update_user_access(access_level, user, project)
    if access_level == :admin
      user.update_attribute(:admin, true)
      enable_admin_mode!(user)
    elsif access_level.present?
      project.add_member(user, access_level)
    end
  end

  def deploy_access_level(access_level)
    case access_level
    when :guest
      Gitlab::Access::GUEST
    when :reporter
      Gitlab::Access::REPORTER
    when :developer
      Gitlab::Access::DEVELOPER
    when :maintainer
      Gitlab::Access::MAINTAINER
    when :admin
      Gitlab::Access::MAINTAINER
    end
  end
end
