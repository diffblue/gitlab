import { GlButton } from '@gitlab/ui';
import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import Api from 'ee/api';
import PolicyRuleBuilder from 'ee/security_orchestration/components/policy_editor/scan_result_policy/policy_rule_builder.vue';
import ProtectedBranchesSelector from 'ee/vue_shared/components/branches_selector/protected_branches_selector.vue';
import PolicyRuleMultiSelect from 'ee/security_orchestration/components/policy_rule_multi_select.vue';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';

describe('PolicyRuleBuilder', () => {
  let wrapper;

  const PROTECTED_BRANCHES_MOCK = [{ id: 1, name: 'main' }];

  const DEFAULT_RULE = {
    type: 'scan_finding',
    branches: [],
    scanners: [],
    vulnerabilities_allowed: 0,
    severity_levels: [],
    vulnerability_states: [],
  };

  const UPDATED_RULE = {
    type: 'scan_finding',
    branches: [PROTECTED_BRANCHES_MOCK[0].name],
    scanners: ['dast'],
    vulnerabilities_allowed: 1,
    severity_levels: ['high'],
    vulnerability_states: ['newly_detected'],
  };

  const factory = (propsData = {}, provide = {}) => {
    wrapper = mountExtended(PolicyRuleBuilder, {
      propsData: {
        initRule: DEFAULT_RULE,
        ...propsData,
      },
      provide: {
        namespaceId: '1',
        namespaceType: NAMESPACE_TYPES.PROJECT,
        ...provide,
      },
    });
  };

  const findBranches = () => wrapper.findComponent(ProtectedBranchesSelector);
  const findBranchesLabel = () => wrapper.findByTestId('branches-label');
  const findGroupLevelBranches = () => wrapper.findByTestId('group-level-branch');
  const findScanners = () => wrapper.findByTestId('scanners-select');
  const findSeverities = () => wrapper.findByTestId('severities-select');
  const findVulnStates = () => wrapper.findByTestId('vulnerability-states-select');
  const findVulnAllowed = () => wrapper.findByTestId('vulnerabilities-allowed-input');
  const findDeleteBtn = () => wrapper.findComponent(GlButton);
  const findAllPolicyRuleMultiSelect = () => wrapper.findAllComponents(PolicyRuleMultiSelect);

  beforeEach(() => {
    jest
      .spyOn(Api, 'projectProtectedBranches')
      .mockReturnValue(Promise.resolve(PROTECTED_BRANCHES_MOCK));
  });

  describe('initial rendering', () => {
    beforeEach(() => {
      factory();
    });

    it('renders one field for each attribute of the rule', () => {
      expect(findBranches().exists()).toBe(true);
      expect(findGroupLevelBranches().exists()).toBe(false);
      expect(findScanners().exists()).toBe(true);
      expect(findSeverities().exists()).toBe(true);
      expect(findVulnStates().exists()).toBe(true);
      expect(findVulnAllowed().exists()).toBe(true);
    });

    it('renders the delete button', () => {
      expect(findDeleteBtn().exists()).toBe(true);
    });

    it('includes select all option to all PolicyRuleMultiSelect', () => {
      const props = findAllPolicyRuleMultiSelect().wrappers.map((w) => w.props());

      expect(props).toEqual(
        expect.arrayContaining([expect.objectContaining({ includeSelectAll: true })]),
      );
    });

    it('emits the remove event when removing the rule', async () => {
      await findDeleteBtn().vm.$emit('click');

      expect(wrapper.emitted().remove).toHaveLength(1);
    });

    it('does not render branches label when targeting all branches', () => {
      expect(findBranchesLabel().exists()).toBe(false);
    });
  });

  describe('when editing any attribute of the rule', () => {
    it.each`
      currentComponent   | newValue                                | expected
      ${findBranches}    | ${PROTECTED_BRANCHES_MOCK[0]}           | ${{ branches: UPDATED_RULE.branches }}
      ${findScanners}    | ${UPDATED_RULE.scanners}                | ${{ scanners: UPDATED_RULE.scanners }}
      ${findSeverities}  | ${UPDATED_RULE.severity_levels}         | ${{ severity_levels: UPDATED_RULE.severity_levels }}
      ${findVulnStates}  | ${UPDATED_RULE.vulnerability_states}    | ${{ vulnerability_states: UPDATED_RULE.vulnerability_states }}
      ${findVulnAllowed} | ${UPDATED_RULE.vulnerabilities_allowed} | ${{ vulnerabilities_allowed: UPDATED_RULE.vulnerabilities_allowed }}
    `(
      'triggers a changed event (by $currentComponent) with the updated rule',
      async ({ currentComponent, newValue, expected }) => {
        factory();
        await nextTick();
        await currentComponent().vm.$emit('input', newValue);

        expect(wrapper.emitted().changed).toEqual([[expect.objectContaining(expected)]]);
      },
    );
  });

  it('does render branches label when a branch is selected', async () => {
    factory({ initRule: UPDATED_RULE });
    await nextTick();
    expect(findBranchesLabel().exists()).toBe(true);
  });

  describe('when namespaceType is other than project', () => {
    it('displays group level branches', async () => {
      factory({}, { namespaceType: NAMESPACE_TYPES.GROUP });
      await nextTick();
      expect(findBranches().exists()).toBe(false);
      expect(findGroupLevelBranches().exists()).toBe(true);
    });

    it('triggers a changed event with the updated rule', async () => {
      factory({}, { namespaceType: NAMESPACE_TYPES.GROUP });
      await nextTick();
      const INPUT_BRANCHES = 'main, test';
      const EXPECTED_BRANCHES = ['main', 'test'];
      await findGroupLevelBranches().vm.$emit('input', INPUT_BRANCHES);

      expect(wrapper.emitted().changed).toEqual([
        [expect.objectContaining({ branches: EXPECTED_BRANCHES })],
      ]);
    });

    it('group level branches is invalid when empty', async () => {
      factory(
        { initRule: { ...DEFAULT_RULE, branches: [''] } },
        { namespaceType: NAMESPACE_TYPES.GROUP },
      );
      await nextTick();

      expect(findGroupLevelBranches().classes('is-invalid')).toBe(true);
    });
  });
});
