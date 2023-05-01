# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::OrchestrationPolicyConfiguration, feature_category: :security_policy_management do
  let_it_be(:security_policy_management_project) { create(:project, :repository) }

  let(:security_orchestration_policy_configuration) do
    create(:security_orchestration_policy_configuration, security_policy_management_project: security_policy_management_project)
  end

  let(:default_branch) { security_policy_management_project.default_branch }
  let(:repository) { instance_double(Repository, root_ref: 'master', empty?: false) }
  let(:policy_yaml) { build(:orchestration_policy_yaml, scan_execution_policy: [build(:scan_execution_policy, name: 'Run DAST in every pipeline')], scan_result_policy: [build(:scan_result_policy, name: 'Containe security critical severities')]) }

  before do
    allow(security_policy_management_project).to receive(:repository).and_return(repository)
    allow(repository).to receive(:blob_data_at).with(default_branch, Security::OrchestrationPolicyConfiguration::POLICY_PATH).and_return(policy_yaml)
  end

  describe 'associations' do
    it { is_expected.to belong_to(:project).inverse_of(:security_orchestration_policy_configuration) }
    it { is_expected.to belong_to(:namespace).inverse_of(:security_orchestration_policy_configuration) }
    it { is_expected.to belong_to(:security_policy_management_project).class_name('Project') }
    it { is_expected.to have_many(:rule_schedules).class_name('Security::OrchestrationPolicyRuleSchedule').inverse_of(:security_orchestration_policy_configuration) }
  end

  describe 'validations' do
    subject { create(:security_orchestration_policy_configuration) }

    context 'when created for project' do
      it { is_expected.not_to validate_presence_of(:namespace) }
      it { is_expected.to validate_presence_of(:project) }
      it { is_expected.to validate_uniqueness_of(:project) }
    end

    context 'when created for namespace' do
      subject { create(:security_orchestration_policy_configuration, :namespace) }

      it { is_expected.not_to validate_presence_of(:project) }
      it { is_expected.to validate_presence_of(:namespace) }
      it { is_expected.to validate_uniqueness_of(:namespace) }
    end

    it { is_expected.to validate_presence_of(:security_policy_management_project) }
  end

  describe '.for_project' do
    let_it_be(:security_orchestration_policy_configuration_1) { create(:security_orchestration_policy_configuration) }
    let_it_be(:security_orchestration_policy_configuration_2) { create(:security_orchestration_policy_configuration) }
    let_it_be(:security_orchestration_policy_configuration_3) { create(:security_orchestration_policy_configuration) }

    subject { described_class.for_project([security_orchestration_policy_configuration_2.project, security_orchestration_policy_configuration_3.project]) }

    it 'returns configuration for given projects' do
      is_expected.to contain_exactly(security_orchestration_policy_configuration_2, security_orchestration_policy_configuration_3)
    end
  end

  describe '.for_namespace' do
    let_it_be(:security_orchestration_policy_configuration_1) { create(:security_orchestration_policy_configuration, :namespace) }
    let_it_be(:security_orchestration_policy_configuration_2) { create(:security_orchestration_policy_configuration, :namespace) }
    let_it_be(:security_orchestration_policy_configuration_3) { create(:security_orchestration_policy_configuration, :namespace) }

    subject { described_class.for_namespace([security_orchestration_policy_configuration_2.namespace, security_orchestration_policy_configuration_3.namespace]) }

    it 'returns configuration for given namespaces' do
      is_expected.to contain_exactly(security_orchestration_policy_configuration_2, security_orchestration_policy_configuration_3)
    end
  end

  describe '.for_management_project' do
    let_it_be(:security_orchestration_policy_configuration_1) { create(:security_orchestration_policy_configuration, security_policy_management_project: security_policy_management_project) }
    let_it_be(:security_orchestration_policy_configuration_2) { create(:security_orchestration_policy_configuration, security_policy_management_project: security_policy_management_project) }
    let_it_be(:security_orchestration_policy_configuration_3) { create(:security_orchestration_policy_configuration) }

    subject { described_class.for_management_project(security_policy_management_project) }

    it 'returns configuration for given the policy management project' do
      is_expected.to contain_exactly(security_orchestration_policy_configuration_1, security_orchestration_policy_configuration_2)
    end
  end

  describe '.with_outdated_configuration' do
    let!(:security_orchestration_policy_configuration_1) { create(:security_orchestration_policy_configuration, configured_at: nil) }
    let!(:security_orchestration_policy_configuration_2) { create(:security_orchestration_policy_configuration, configured_at: Time.zone.now - 1.hour) }
    let!(:security_orchestration_policy_configuration_3) { create(:security_orchestration_policy_configuration, configured_at: Time.zone.now + 1.hour) }

    subject { described_class.with_outdated_configuration }

    it 'returns configuration with outdated configurations' do
      is_expected.to contain_exactly(security_orchestration_policy_configuration_1, security_orchestration_policy_configuration_2)
    end
  end

  describe '.for_bot_user' do
    let_it_be(:bot_user) { create(:user, user_type: :security_policy_bot) }
    let_it_be(:security_orchestration_policy_configuration_1) { create(:security_orchestration_policy_configuration) }
    let_it_be(:security_orchestration_policy_configuration_2) { create(:security_orchestration_policy_configuration, bot_user: bot_user) }
    let_it_be(:security_orchestration_policy_configuration_3) { create(:security_orchestration_policy_configuration, bot_user: bot_user) }

    subject { described_class.for_bot_user(bot_user) }

    it 'returns configurations for the given bot user' do
      is_expected.to contain_exactly(security_orchestration_policy_configuration_2, security_orchestration_policy_configuration_3)
    end
  end

  describe '.policy_management_project?' do
    before do
      create(:security_orchestration_policy_configuration, security_policy_management_project: security_policy_management_project)
    end

    it 'returns true when security_policy_management_project with id exists' do
      expect(described_class.policy_management_project?(security_policy_management_project.id)).to be_truthy
    end

    it 'returns false when security_policy_management_project with id does not exist' do
      expect(described_class.policy_management_project?(non_existing_record_id)).to be_falsey
    end
  end

  describe '.valid_scan_type?' do
    it 'returns true when scan type is valid' do
      expect(Security::ScanExecutionPolicy.valid_scan_type?('secret_detection')).to be_truthy
    end

    it 'returns false when scan type is invalid' do
      expect(Security::ScanExecutionPolicy.valid_scan_type?('invalid')).to be_falsey
    end
  end

  describe '#policy_configuration_exists?' do
    subject { security_orchestration_policy_configuration.policy_configuration_exists? }

    context 'when file is missing' do
      let(:policy_yaml) { nil }

      it { is_expected.to eq(false) }
    end

    context 'when policy is present' do
      it { is_expected.to eq(true) }
    end
  end

  describe '#policy_hash' do
    subject { security_orchestration_policy_configuration.policy_hash }

    context 'when policy is present' do
      it { expect(subject.dig(:scan_execution_policy, 0, :name)).to eq('Run DAST in every pipeline') }
    end

    context 'when policy has invalid YAML format' do
      let(:policy_yaml) do
        'cadence: * 1 2 3'
      end

      it { expect(subject).to be_nil }
    end

    context 'when policy is nil' do
      let(:policy_yaml) { nil }

      it { expect(subject).to be_nil }
    end
  end

  describe '#policy_by_type' do
    subject { security_orchestration_policy_configuration.policy_by_type(:scan_execution_policy) }

    before do
      allow(security_policy_management_project).to receive(:repository).and_return(repository)
      allow(repository).to receive(:blob_data_at).with(default_branch, Security::OrchestrationPolicyConfiguration::POLICY_PATH).and_return(policy_yaml)
    end

    context 'when policy is present' do
      let(:policy_yaml) { build(:orchestration_policy_yaml, scan_execution_policy: [build(:scan_execution_policy, name: 'Run DAST in every pipeline' )]) }

      it 'retrieves policy by type' do
        expect(subject.first[:name]).to eq('Run DAST in every pipeline')
      end
    end

    context 'when policy is nil' do
      let(:policy_yaml) { nil }

      it 'returns an empty array' do
        expect(subject).to eq([])
      end
    end
  end

  describe '#policy_configuration_valid?' do
    subject { security_orchestration_policy_configuration.policy_configuration_valid? }

    context 'when file is invalid' do
      let(:policy_yaml) do
        build(:orchestration_policy_yaml, scan_execution_policy:
        [build(:scan_execution_policy, rules: [{ type: 'pipeline', branches: 'production' }])])
      end

      it { is_expected.to eq(false) }
    end

    context 'when file has invalid name' do
      let(:invalid_name) { 'a' * 256 }
      let(:policy_yaml) do
        build(:orchestration_policy_yaml, scan_execution_policy:
        [build(:scan_execution_policy, name: invalid_name)])
      end

      it { is_expected.to be false }
    end

    context 'when file is valid' do
      it { is_expected.to eq(true) }

      context 'with license_scanning policy' do
        let(:policy_yaml) do
          build(:orchestration_policy_yaml,
                scan_execution_policy: [],
                scan_result_policy: [build(:scan_result_policy, :license_finding)])
        end

        it { is_expected.to eq(true) }
      end
    end

    context 'when policy is passed as argument' do
      let_it_be(:policy_yaml) { nil }
      let_it_be(:policy) { { scan_execution_policy: [build(:scan_execution_policy)] } }

      context 'when scan type is secret_detection' do
        it 'returns false if extra fields are present' do
          invalid_policy = policy.deep_dup
          invalid_policy[:scan_execution_policy][0][:actions][0][:scan] = 'secret_detection'
          invalid_policy[:scan_execution_policy][0][:actions][0][:variables] = { 'SECRET_DETECTION_HISTORIC_SCAN' => 'false' }

          expect(security_orchestration_policy_configuration.policy_configuration_valid?(invalid_policy)).to be_falsey
        end

        it 'returns true if extra fields are not present' do
          valid_policy = policy.deep_dup
          valid_policy[:scan_execution_policy][0][:actions][0] = { scan: 'secret_detection' }

          expect(security_orchestration_policy_configuration.policy_configuration_valid?(valid_policy)).to be_truthy
        end
      end

      context 'for schedule policy rule' do
        using RSpec::Parameterized::TableSyntax

        let_it_be(:schedule_policy) { { scan_execution_policy: [build(:scan_execution_policy, :with_schedule)] } }

        subject { security_orchestration_policy_configuration.policy_configuration_valid?(schedule_policy) }

        where(:cadence, :is_valid) do
          "@weekly"           | true
          "@yearly"           | true
          "@annually"         | true
          "@monthly"          | true
          "@weekly"           | true
          "@daily"            | true
          "@midnight"         | true
          "@noon"             | true
          "@hourly"           | true
          "* * * * *"         | true
          "0 0 2 3 *"         | true
          "* * L * *"         | true
          "* * -6 * *"        | true
          "* * -3 * *"        | true
          "* * 12 * *"        | true
          "0 9 -4 * *"        | true
          "0 0 -8 * *"        | true
          "7 10 * * *"        | true
          "00 07 * * *"       | true
          "* * * * tue"       | true
          "* * * * TUE"       | true
          "12 10 0 * *"       | true
          "52 20 * * 2"       | true
          "* * last * *"      | true
          "0 2 last * *"      | true
          "52 9 2-5 * 2"      | true
          "0 0 27 3 1,5"      | true
          "0 0 11 * 3-6"      | true
          "0 0 -7-L * *"      | true
          "0 0 -1,-2 * *"     | true
          "10/30 * * * *"     | true
          "21 37 4,12 * 3"    | true
          "02 07 21 jan *"    | true
          "02 07 21 JAN *"    | true
          "0 1 L * wed-fri"   | true
          "0 1 L * wed-FRI"   | true
          "0 1 L * WED-fri"   | true
          "0 1 L * WED-FRI"   | true
          "0 0 21 4 sat,sun"  | true
          "0 0 21 4 SAT,SUN"  | true
          "10-30/30 * * * *"  | true

          ""                  | false
          "1"                 | false
          "2 3 4"             | false
          "invalid"           | false
          "@WEEKLY"           | false
          "@YEARLY"           | false
          "@ANNUALLY"         | false
          "@MONTHLY"          | false
          "@WEEKLY"           | false
          "@DAILY"            | false
          "@MIDNIGHT"         | false
          "@NOON"             | false
          "@HOURLY"           | false
        end

        with_them do
          before do
            schedule_policy[:scan_execution_policy][0][:rules][0][:cadence] = cadence
          end

          it { is_expected.to eq(is_valid) }
        end
      end
    end

    context 'with scan result policies' do
      let(:policy_name) { 'Contains security critical severities' }
      let(:scan_result_policy) { build(:scan_result_policy, name: policy_name) }
      let(:policy_yaml) { build(:orchestration_policy_yaml, scan_result_policy: [scan_result_policy]) }

      it { is_expected.to eq(true) }

      context 'with various approvers' do
        using RSpec::Parameterized::TableSyntax

        where(:user_approvers, :user_approvers_ids, :group_approvers, :group_approvers_ids, :role_approvers, :is_valid) do
          []           | nil  | nil            | nil | nil | false
          ['username'] | nil  | nil            | nil | nil | true
          nil          | []   | nil            | nil | nil | false
          nil          | [1]  | nil            | nil | nil | true
          nil          | nil  | []             | nil | nil | false
          nil          | nil  | ['group_path'] | nil | nil | true
          nil          | nil  | nil            | []  | nil | false
          nil          | nil  | nil            | [2] | nil | true
          nil          | nil  | nil            | nil | [] | false
          nil          | nil  | nil            | nil | ['developer'] | true
        end

        with_them do
          let(:action) do
            { type: 'require_approval',
              approvals_required: 1,
              user_approvers: user_approvers,
              user_approvers_ids: user_approvers_ids,
              group_approvers: group_approvers,
              group_approvers_ids: group_approvers_ids,
              role_approvers: role_approvers }.compact
          end

          let(:scan_result_policy) { build(:scan_result_policy, name: 'Contains security critical severities', actions: [action]) }

          it { is_expected.to eq(is_valid) }
        end
      end

      context 'with various policy names' do
        using RSpec::Parameterized::TableSyntax

        where(:policy_name, :expected_to_be_valid) do
          ApprovalRuleLike::DEFAULT_NAME_FOR_LICENSE_REPORT                 | false
          ApprovalRuleLike::DEFAULT_NAME_FOR_COVERAGE                       | false
          "New #{ApprovalRuleLike::DEFAULT_NAME_FOR_LICENSE_REPORT}"        | true
          "#{ApprovalRuleLike::DEFAULT_NAME_FOR_COVERAGE} through policies" | true
        end

        with_them do
          it { is_expected.to eq(expected_to_be_valid) }
        end
      end
    end
  end

  describe '#policy_configuration_validation_errors' do
    let(:scan_execution_policy) { nil }
    let(:scan_result_policy) { nil }

    let(:policy_yaml) do
      {
        scan_execution_policy: [scan_execution_policy].compact,
        scan_result_policy: [scan_result_policy].compact
      }
    end

    subject(:errors) do
      security_orchestration_policy_configuration.policy_configuration_validation_errors(policy_yaml)
    end

    context "without policies" do
      let(:policy_yaml) { {} }

      specify do
        expect(errors).to contain_exactly("root is missing required keys: scan_execution_policy",
          "root is missing required keys: scan_result_policy")
      end
    end

    describe "scan execution policies" do
      let(:scan_execution_policy) { build(:scan_execution_policy, rules: rules, actions: actions) }
      let(:rules) { [rule].compact }
      let(:rule) { nil }
      let(:actions) { [action].compact }
      let(:action) { nil }

      %i[name enabled rules actions].each do |key|
        context "without #{key}" do
          before do
            scan_execution_policy.delete(key)
          end

          specify do
            expect(errors).to contain_exactly("property '/scan_execution_policy/0' is missing required keys: #{key}")
          end
        end
      end

      describe "name" do
        context "when too short" do
          before do
            scan_execution_policy[:name] = ""
          end

          specify do
            expect(errors).to contain_exactly("property '/scan_execution_policy/0/name' is invalid: error_type=minLength")
          end
        end

        context "when too long" do
          before do
            scan_execution_policy[:name] = "a" * 256
          end

          specify do
            expect(errors).to contain_exactly("property '/scan_execution_policy/0/name' is invalid: error_type=maxLength")
          end
        end
      end

      describe "rules" do
        context "with invalid type" do
          let(:rule) { { type: "foobar" } }

          specify do
            expect(errors.count).to be(1)
            expect(errors.first).to match("property '/scan_execution_policy/0/rules/0/type' is not one of")
          end
        end

        context "with schedule type" do
          let(:rule) { { type: "schedule", branches: %w[master], cadence: "5 4 * * *" } }

          specify { expect(errors).to be_empty }

          context "with invalid cadence" do
            before do
              rule[:cadence] = "foobar"
            end

            specify do
              expect(errors.count).to be(1)
              expect(errors.first).to match("property '/scan_execution_policy/0/rules/0/cadence' does not match pattern")
            end
          end
        end

        context "with schedule type and agent" do
          let(:rule) { { type: "schedule", agents: { foo: { namespaces: %w[bar] } }, cadence: "5 4 * * *" } }

          specify { expect(errors).to be_empty }

          context "with invalid agent name" do
            before do
              rule[:agents][:"with spaces"] = rule[:agents].delete(:foo)
            end

            specify do
              expect(errors.count).to be(1)
              expect(errors.first).to match(
                "property '/scan_execution_policy/0/rules/0/agents/with spaces' is invalid: error_type=schema")
            end
          end
        end
      end

      describe "actions" do
        let(:action) { { scan: "container_scanning" } }

        specify { expect(errors).to be_empty }

        context "with invalid scan" do
          before do
            action[:scan] = "foobar"
          end

          specify do
            expect(errors.count).to be(1)
            expect(errors.first).to match("property '/scan_execution_policy/0/actions/0/scan' is not one of")
          end
        end

        context "with DAST scan" do
          let(:action) { { scan: "dast", site_profile: "Site Profile", scanner_profile: "Scanner Profile" } }

          specify { expect(errors).to be_empty }

          context "without site profile" do
            before do
              action.delete(:site_profile)
            end

            specify do
              expect(errors).to contain_exactly(
                "property '/scan_execution_policy/0/actions/0' is missing required keys: site_profile")
            end
          end

          context "without scanner profile" do
            before do
              action.delete(:scanner_profile)
            end

            specify { expect(errors).to be_empty }
          end
        end

        context "with variables" do
          let(:action) { { scan: "container_scanning", variables: { "FOO" => "BAR" } } }

          specify { expect(errors).to be_empty }

          context "with invalid key" do
            before do
              action[:variables]["with spaces"] = action[:variables].delete("FOO")
            end

            specify do
              expect(errors.count).to be(1)
              expect(errors.first).to match(
                "property '/scan_execution_policy/0/actions/0/variables/with spaces' is invalid: error_type=schema")
            end
          end
        end
      end
    end

    describe "scan result policies" do
      let(:scan_execution_policy) { nil }
      let(:scan_result_policy) { build(:scan_result_policy, rules: rules, actions: actions) }
      let(:rules) { [rule].compact }
      let(:actions) { [action].compact }
      let(:action) { nil }

      shared_examples "scan result policy" do |required_rule_keys|
        %i[name enabled rules actions].each do |key|
          context "without #{key}" do
            before do
              scan_result_policy.delete(key)
            end

            specify do
              expect(errors).to contain_exactly("property '/scan_result_policy/0' is missing required keys: #{key}")
            end
          end
        end

        required_rule_keys.each do |key|
          context "without #{key}" do
            before do
              rule.delete(key)
            end

            specify do
              expect(errors).to contain_exactly(
                "property '/scan_result_policy/0/rules/0' is missing required keys: #{key}")
            end
          end
        end

        describe "name" do
          context "when too short" do
            before do
              scan_result_policy[:name] = ""
            end

            specify do
              expect(errors).to contain_exactly("property '/scan_result_policy/0/name' is invalid: error_type=minLength")
            end
          end

          context "when too long" do
            before do
              scan_result_policy[:name] = "a" * 256
            end

            specify do
              expect(errors).to contain_exactly("property '/scan_result_policy/0/name' is invalid: error_type=maxLength")
            end
          end
        end

        describe "rules" do
          context "with invalid type" do
            before do
              rule[:type] = "foobar"
            end

            specify do
              expect(errors.count).to be(1)
              expect(errors.first).to match("property '/scan_result_policy/0/rules/0/type' is not one of")
            end
          end
        end

        describe "actions" do
          let(:action) do
            {
              type: "require_approval",
              approvals_required: 1
            }
          end

          context "without approvers" do
            specify do
              expect(errors).not_to be_empty
            end
          end

          context "with user_approvers" do
            before do
              action[:user_approvers] = %w[foobar]
            end

            specify { expect(errors).to be_empty }

            context "when empty" do
              before do
                action[:user_approvers] = []
              end

              specify do
                expect(errors).to contain_exactly(
                  "property '/scan_result_policy/0/actions/0/user_approvers' is invalid: error_type=minItems")
              end
            end
          end

          context "with user_approvers_ids" do
            before do
              action[:user_approvers_ids] = [42]
            end

            specify { expect(errors).to be_empty }

            context "when empty" do
              before do
                action[:user_approvers_ids] = []
              end

              specify do
                expect(errors).to contain_exactly(
                  "property '/scan_result_policy/0/actions/0/user_approvers_ids' is invalid: error_type=minItems")
              end
            end
          end

          context "with group_approvers" do
            before do
              action[:group_approvers] = %w[foobar]
            end

            specify { expect(errors).to be_empty }

            context "when empty" do
              before do
                action[:group_approvers] = []
              end

              specify do
                expect(errors).to contain_exactly(
                  "property '/scan_result_policy/0/actions/0/group_approvers' is invalid: error_type=minItems")
              end
            end
          end

          context "with group_approvers_ids" do
            before do
              action[:group_approvers_ids] = [42]
            end

            specify { expect(errors).to be_empty }

            context "when empty" do
              before do
                action[:group_approvers_ids] = []
              end

              specify do
                expect(errors).to contain_exactly(
                  "property '/scan_result_policy/0/actions/0/group_approvers_ids' is invalid: error_type=minItems")
              end
            end
          end

          context "with role_approvers" do
            before do
              action[:role_approvers] = %w[guest reporter]
            end

            specify { expect(errors).to be_empty }

            context "with invalid role" do
              before do
                action[:role_approvers] = %w[foobar]
              end

              specify do
                expect(errors.count).to be(1)
                expect(errors.first).to match("property '/scan_result_policy/0/actions/0/role_approvers/0' is not one of")
              end
            end
          end
        end
      end

      context "with scan_finding type" do
        let(:rule) do
          {
            type: "scan_finding",
            branches: %w[master],
            scanners: %w[container_scanning secret_detection],
            vulnerabilities_allowed: 0,
            severity_levels: %w[critical high],
            vulnerability_states: %w[detected]
          }
        end

        specify { expect(errors).to be_empty }

        it_behaves_like "scan result policy",
          %i[branches scanners vulnerabilities_allowed severity_levels vulnerability_states]

        describe "scanners" do
          before do
            rule[:scanners] = [""]
          end

          specify do
            expect(errors).to contain_exactly(
              "property '/scan_result_policy/0/rules/0/scanners/0' is invalid: error_type=minLength")
          end
        end

        describe "severity_levels" do
          before do
            rule[:severity_levels] = %w[foobar]
          end

          specify do
            expect(errors.count).to be(1)
            expect(errors.first).to match("property '/scan_result_policy/0/rules/0/severity_levels/0' is not one of")
          end
        end

        describe "vulnerability_states" do
          before do
            rule[:vulnerability_states] = %w[foobar]
          end

          specify do
            expect(errors.count).to be(1)
            expect(errors.first).to match(
              "property '/scan_result_policy/0/rules/0/vulnerability_states/0' is not one of")
          end
        end
      end

      context "with license_finding type" do
        let(:rule) do
          {
            type: "license_finding",
            branches: %w[master],
            match_on_inclusion: true,
            license_types: %w[BSD MIT],
            license_states: %w[newly_detected detected]
          }
        end

        specify { expect(errors).to be_empty }

        it_behaves_like "scan result policy", %i[branches match_on_inclusion license_types license_states]

        describe "license_types" do
          before do
            rule[:license_types] = [""]
          end

          specify do
            expect(errors).to contain_exactly(
              "property '/scan_result_policy/0/rules/0/license_types/0' is invalid: error_type=minLength")
          end
        end

        describe "license_states" do
          context "without states" do
            before do
              rule[:license_states] = []
            end

            specify do
              expect(errors).to contain_exactly(
                "property '/scan_result_policy/0/rules/0/license_states' is invalid: error_type=minItems")
            end
          end

          context "with invalid state" do
            before do
              rule[:license_states] = %w[foobar]
            end

            specify do
              expect(errors.count).to be(1)
              expect(errors.first).to match(
                "property '/scan_result_policy/0/rules/0/license_states/0' is not one of")
            end
          end
        end
      end
    end

    context 'when file is valid' do
      it { is_expected.to eq([]) }
    end

    context 'when policy is passed as argument' do
      let_it_be(:policy_yaml) { nil }
      let_it_be(:policy) { { scan_execution_policy: [build(:scan_execution_policy, :with_schedule)] } }

      context 'when scan type is secret_detection' do
        it 'returns false if extra fields are present' do
          invalid_policy = policy.deep_dup
          invalid_policy[:scan_execution_policy][0][:actions][0][:scan] = 'secret_detection'
          invalid_policy[:scan_execution_policy][0][:actions][0][:variables] = { 'SECRET_DETECTION_HISTORIC_SCAN' => 'false' }
          invalid_policy[:scan_execution_policy][0][:rules][0][:cadence] = 'invalid * * * *'

          expect(security_orchestration_policy_configuration.policy_configuration_validation_errors(invalid_policy)).to contain_exactly(
            "property '/scan_execution_policy/0/actions/0' is invalid: error_type=maxProperties",
            "property '/scan_execution_policy/0/rules/0/cadence' does not match pattern: (@(yearly|annually|monthly|weekly|daily|midnight|noon|hourly))|(((\\*|(\\-?\\d+\\,?)+)(\\/\\d+)?|last|L|(sun|mon|tue|wed|thu|fri|sat|SUN|MON|TUE|WED|THU|FRI|SAT\\-|\\,)+|(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec|JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC|\\-|\\,)+)\\s?){5,6}"
          )
        end

        it 'returns true if extra fields are not present' do
          valid_policy = policy.deep_dup
          valid_policy[:scan_execution_policy][0][:actions][0] = { scan: 'secret_detection' }

          expect(security_orchestration_policy_configuration.policy_configuration_validation_errors(valid_policy)).to eq([])
        end
      end
    end
  end

  describe '#active_scan_execution_policies' do
    let(:enforce_dast_yaml) { build(:orchestration_policy_yaml, scan_execution_policy: [build(:scan_execution_policy)]) }
    let(:policy_yaml) { fixture_file('security_orchestration.yml', dir: 'ee') }

    let(:expected_active_policies) do
      [
        build(:scan_execution_policy, name: 'Run DAST in every pipeline', rules: [{ type: 'pipeline', branches: %w[production] }]),
        build(:scan_execution_policy, name: 'Run DAST in every pipeline_v1', rules: [{ type: 'pipeline', branches: %w[master] }]),
        build(:scan_execution_policy, name: 'Run DAST in every pipeline_v3', rules: [{ type: 'pipeline', branches: %w[master] }]),
        build(:scan_execution_policy, name: 'Run DAST in every pipeline_v4', rules: [{ type: 'pipeline', branches: %w[master] }]),
        build(:scan_execution_policy, name: 'Run DAST in every pipeline_v5', rules: [{ type: 'pipeline', branches: %w[master] }])
      ]
    end

    subject(:active_scan_execution_policies) { security_orchestration_policy_configuration.active_scan_execution_policies }

    before do
      allow(security_policy_management_project).to receive(:repository).and_return(repository)
      allow(repository).to receive(:blob_data_at).with( default_branch, Security::OrchestrationPolicyConfiguration::POLICY_PATH).and_return(policy_yaml)
    end

    it 'returns only enabled policies' do
      expect(active_scan_execution_policies).to eq(expected_active_policies)
    end
  end

  describe '#active_policy_names_with_dast_site_profile' do
    let(:policy_yaml) do
      build(:orchestration_policy_yaml, scan_execution_policy: [
              build(:scan_execution_policy,
                    name: 'Run DAST in every pipeline',
                    actions: [
                      { scan: 'dast', site_profile: 'Site Profile', scanner_profile: 'Scanner Profile' },
                      { scan: 'dast', site_profile: 'Site Profile', scanner_profile: 'Scanner Profile 2' }
                    ])
            ])
    end

    it 'returns list of policy names where site profile is referenced' do
      expect( security_orchestration_policy_configuration.active_policy_names_with_dast_site_profile('Site Profile')).to contain_exactly('Run DAST in every pipeline')
    end
  end

  describe '#active_policy_names_with_dast_scanner_profile' do
    let(:enforce_dast_yaml) do
      build(:orchestration_policy_yaml, scan_execution_policy: [
              build(:scan_execution_policy,
                    name: 'Run DAST in every pipeline',
                    actions: [
                      { scan: 'dast', site_profile: 'Site Profile', scanner_profile: 'Scanner Profile' },
                      { scan: 'dast', site_profile: 'Site Profile 2', scanner_profile: 'Scanner Profile' }
                    ])
            ])
    end

    before do
      allow(security_policy_management_project).to receive(:repository).and_return(repository)
      allow(repository).to receive(:blob_data_at).with(default_branch, Security::OrchestrationPolicyConfiguration::POLICY_PATH).and_return(enforce_dast_yaml)
    end

    it 'returns list of policy names where site profile is referenced' do
      expect(security_orchestration_policy_configuration.active_policy_names_with_dast_scanner_profile('Scanner Profile')).to contain_exactly('Run DAST in every pipeline')
    end
  end

  describe '#policy_last_updated_by' do
    let(:commit) { create(:commit, author: security_policy_management_project.first_owner) }

    subject(:policy_last_updated_by) { security_orchestration_policy_configuration.policy_last_updated_by }

    before do
      allow(security_policy_management_project).to receive(:repository).and_return(repository)
      allow(repository).to receive(:last_commit_for_path).with(default_branch, Security::OrchestrationPolicyConfiguration::POLICY_PATH).and_return(commit)
    end

    context 'when last commit to policy file exists' do
      it { is_expected.to eq(security_policy_management_project.first_owner) }
    end

    context 'when last commit to policy file does not exist' do
      let(:commit) {}

      it { is_expected.to be_nil }
    end
  end

  describe '#policy_last_updated_at' do
    let(:last_commit_updated_at) { Time.zone.now }
    let(:commit) { create(:commit) }

    subject(:policy_last_updated_at) { security_orchestration_policy_configuration.policy_last_updated_at }

    before do
      allow(security_policy_management_project).to receive(:repository).and_return(repository)
      allow(repository).to receive(:last_commit_for_path).and_return(commit)
    end

    context 'when last commit to policy file exists' do
      it "returns commit's updated date" do
        commit.committed_date = last_commit_updated_at

        is_expected.to eq(policy_last_updated_at)
      end
    end

    context 'when last commit to policy file does not exist' do
      let(:commit) {}

      it { is_expected.to be_nil }
    end
  end

  describe '#delete_all_schedules' do
    let(:rule_schedule) { create(:security_orchestration_policy_rule_schedule, security_orchestration_policy_configuration: security_orchestration_policy_configuration) }

    subject(:delete_all_schedules) { security_orchestration_policy_configuration.delete_all_schedules }

    it 'deletes all schedules belonging to configuration' do
      delete_all_schedules

      expect(security_orchestration_policy_configuration.rule_schedules).to be_empty
    end
  end

  describe '#active_scan_result_policies' do
    let(:scan_result_yaml) { build(:orchestration_policy_yaml, scan_result_policy: [build(:scan_result_policy)]) }
    let(:policy_yaml) { fixture_file('security_orchestration.yml', dir: 'ee') }

    subject(:active_scan_result_policies) { security_orchestration_policy_configuration.active_scan_result_policies }

    before do
      allow(security_policy_management_project).to receive(:repository).and_return(repository)
      allow(repository).to receive(:blob_data_at).with(default_branch, Security::OrchestrationPolicyConfiguration::POLICY_PATH).and_return(policy_yaml)
    end

    it 'returns only enabled policies' do
      expect(active_scan_result_policies.pluck(:enabled).uniq).to contain_exactly(true)
    end

    it 'returns only 5 from all active policies' do
      expect(active_scan_result_policies.count).to be(5)
    end

    context 'when policy configuration is configured for namespace' do
      let(:security_orchestration_policy_configuration) do
        create(:security_orchestration_policy_configuration, :namespace, security_policy_management_project: security_policy_management_project)
      end

      it 'returns only enabled policies' do
        expect(active_scan_result_policies.pluck(:enabled).uniq).to contain_exactly(true)
      end

      it 'returns only 5 from all active policies' do
        expect(active_scan_result_policies.count).to be(5)
      end
    end
  end

  describe '#scan_result_policies' do
    let(:policy_yaml) { fixture_file('security_orchestration.yml', dir: 'ee') }

    subject(:scan_result_policies) { security_orchestration_policy_configuration.scan_result_policies }

    it 'returns all scan result policies' do
      expect(scan_result_policies.pluck(:enabled)).to contain_exactly(true, true, false, true, true, true, true, true)
    end
  end

  describe '#project?' do
    subject { security_orchestration_policy_configuration.project? }

    context 'when project is assigned to policy configuration' do
      it { is_expected.to eq true }
    end

    context 'when namespace is assigned to policy configuration' do
      let(:security_orchestration_policy_configuration) { create(:security_orchestration_policy_configuration, :namespace) }

      it { is_expected.to eq false }
    end
  end

  describe '#namespace?' do
    subject { security_orchestration_policy_configuration.namespace? }

    context 'when project is assigned to policy configuration' do
      it { is_expected.to eq false }
    end

    context 'when namespace is assigned to policy configuration' do
      let(:security_orchestration_policy_configuration) { create(:security_orchestration_policy_configuration, :namespace) }

      it { is_expected.to eq true }
    end
  end

  describe '#source' do
    subject { security_orchestration_policy_configuration.source }

    context 'when project is assigned to policy configuration' do
      it { is_expected.to eq security_orchestration_policy_configuration.project }
    end

    context 'when namespace is assigned to policy configuration' do
      let(:security_orchestration_policy_configuration) { create(:security_orchestration_policy_configuration, :namespace) }

      it { is_expected.to eq security_orchestration_policy_configuration.namespace }
    end
  end

  describe '#delete_scan_finding_rules' do
    subject(:delete_scan_finding_rules) { security_orchestration_policy_configuration.delete_scan_finding_rules }

    let(:project) { security_orchestration_policy_configuration.project }
    let(:merge_request) { create(:merge_request, target_project: project, source_project: project) }
    let(:security_orchestration_policy_configuration_id) { security_orchestration_policy_configuration.id }

    before do
      create(:approval_project_rule,
        :scan_finding,
        project: project,
        security_orchestration_policy_configuration_id: security_orchestration_policy_configuration_id)
      create(:report_approver_rule,
        :scan_finding,
        merge_request: merge_request,
        security_orchestration_policy_configuration_id: security_orchestration_policy_configuration_id)
    end

    shared_examples 'approval rules deletion' do
      it 'deletes project approval rules' do
        expect { delete_scan_finding_rules }.to change(ApprovalProjectRule, :count).from(1).to(0)
      end

      it 'deletes merge request approval rules' do
        expect { delete_scan_finding_rules }.to change(ApprovalMergeRequestRule, :count).from(1).to(0)
      end
    end

    context 'when associated to a project' do
      it_behaves_like 'approval rules deletion'
    end

    context 'when associated to namespace' do
      let(:project) { create(:project) }
      let(:security_orchestration_policy_configuration) do
        create(:security_orchestration_policy_configuration, :namespace)
      end

      it_behaves_like 'approval rules deletion'
    end
  end

  describe '#delete_scan_finding_rules_for_project' do
    subject(:delete_scan_finding_rules_for_project) { security_orchestration_policy_configuration.delete_scan_finding_rules_for_project(project.id) }

    let(:project) { security_orchestration_policy_configuration.project }
    let(:merge_request) { create(:merge_request, target_project: project, source_project: project) }
    let(:security_orchestration_policy_configuration_id) { security_orchestration_policy_configuration.id }

    before do
      create(:approval_project_rule,
        :scan_finding,
        project: project,
        security_orchestration_policy_configuration_id: security_orchestration_policy_configuration_id)
      create(:report_approver_rule,
        :scan_finding,
        merge_request: merge_request,
        security_orchestration_policy_configuration_id: security_orchestration_policy_configuration_id)
    end

    it 'deletes project approval rules' do
      expect { delete_scan_finding_rules_for_project }.to change(ApprovalProjectRule, :count).from(1).to(0)
    end

    it 'deletes merge request approval rules' do
      expect { delete_scan_finding_rules_for_project }.to change(ApprovalMergeRequestRule, :count).from(1).to(0)
    end

    context 'with unrelated resources' do
      let_it_be(:unrelated_project) { create(:project) }
      let(:unrelated_mr) { create(:merge_request, target_project: unrelated_project, source_project: unrelated_project) }

      before do
        create(:approval_project_rule,
          :scan_finding,
          project: unrelated_project,
          security_orchestration_policy_configuration_id: security_orchestration_policy_configuration_id)
        create(:report_approver_rule,
          :scan_finding,
          merge_request: unrelated_mr,
          security_orchestration_policy_configuration_id: security_orchestration_policy_configuration_id)
      end

      it 'does not delete unrelated project approval rules' do
        expect { delete_scan_finding_rules_for_project }.to change(ApprovalProjectRule, :count).from(2).to(1)
      end

      it 'does not delete unrelated merge request approval rules' do
        expect { delete_scan_finding_rules_for_project }.to change(ApprovalMergeRequestRule, :count).from(2).to(1)
      end
    end
  end

  describe '#delete_software_license_policies' do
    let(:configuration) { create(:security_orchestration_policy_configuration) }
    let(:other_configuration) { create(:security_orchestration_policy_configuration) }

    let(:scan_result_policy_read) do
      create(:scan_result_policy_read, security_orchestration_policy_configuration: configuration)
    end

    let(:scan_result_policy_read_other_configuration) do
      create(:scan_result_policy_read, security_orchestration_policy_configuration: other_configuration)
    end

    let!(:software_license_without_scan_result_policy) do
      create(:software_license_policy, project: configuration.project)
    end

    let!(:software_license_with_scan_result_policy) do
      create(:software_license_policy, project: configuration.project,
        scan_result_policy_read: scan_result_policy_read)
    end

    let!(:software_license_with_scan_result_policy_other_configuration) do
      create(:software_license_policy, project: other_configuration.project,
        scan_result_policy_read: scan_result_policy_read_other_configuration)
    end

    it 'deletes project scan_result_policy_reads' do
      configuration.delete_software_license_policies(configuration.project)

      software_license_policies = SoftwareLicensePolicy.where(project_id: configuration.project.id)
      other_project_software_license_policies = SoftwareLicensePolicy.where(project_id: other_configuration.project)

      expect(software_license_policies).to match_array([software_license_without_scan_result_policy])
      expect(other_project_software_license_policies).to match_array([software_license_with_scan_result_policy_other_configuration])
    end
  end

  describe "#active_policies_scan_actions" do
    before do
      allow(Gitlab::Git).to receive(:branch_ref?).with(default_branch).and_return(true)
      allow(Gitlab::Git).to receive(:ref_name).with(default_branch).and_return(default_branch)
    end

    let(:policy_yaml) do
      build(:orchestration_policy_yaml, scan_execution_policy: scan_execution_policies, scan_result_policy: scan_result_policies)
    end

    let(:scan_execution_policies) do
      [dast_policy, container_scanning_policy]
    end

    let(:dast_policy) do
      build(:scan_execution_policy, actions: [{ scan: 'dast',
                                                site_profile: 'Site Profile',
                                                scanner_profile: 'Scanner Profile' }])
    end

    let(:container_scanning_policy) do
      build(:scan_execution_policy, actions: [{ scan: 'container_scanning' }])
    end

    let(:scan_result_policies) do
      [build(:scan_result_policy)]
    end

    subject { security_orchestration_policy_configuration.active_policies_scan_actions(default_branch) }

    it "returns active scan policies" do
      expect(subject).to match_array([*dast_policy[:actions], *container_scanning_policy[:actions]])
    end

    context "with disabled scan policies" do
      let(:container_scanning_policy) do
        build(:scan_execution_policy, actions: [{ scan: 'container_scanning' }], enabled: false)
      end

      it "filters" do
        expect(subject).to match_array(dast_policy[:actions])
      end
    end

    context "with scan policies targeting other branch" do
      let(:container_scanning_policy) do
        build(:scan_execution_policy,
              actions: [{ scan: 'container_scanning' }],
              rules: [{ type: 'pipeline', branches: [default_branch.reverse] }])
      end

      it "filters" do
        expect(subject).to match_array(dast_policy[:actions])
      end
    end
  end
end
