import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import Api from 'ee/api';
import SecurityScanRuleBuilder from 'ee/security_orchestration/components/policy_editor/scan_result_policy/security_scan_rule_builder.vue';
import ProtectedBranchesSelector from 'ee/vue_shared/components/branches_selector/protected_branches_selector.vue';
import PolicyRuleMultiSelect from 'ee/security_orchestration/components/policy_rule_multi_select.vue';
import SeverityFilter from 'ee/security_orchestration/components/policy_editor/scan_result_policy/scan_filters/severity_filter.vue';
import StatusFilter from 'ee/security_orchestration/components/policy_editor/scan_result_policy/scan_filters/status_filter.vue';
import ScanTypeSelect from 'ee/security_orchestration/components/policy_editor/scan_result_policy/base_layout/scan_type_select.vue';
import ScanFilterSelector from 'ee/security_orchestration/components/policy_editor/scan_result_policy/scan_filters/scan_filter_selector.vue';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';
import {
  securityScanBuildRule,
  SCAN_FINDING,
} from 'ee/security_orchestration/components/policy_editor/scan_result_policy/lib/rules';
import { getDefaultRule } from 'ee/security_orchestration/components/policy_editor/scan_result_policy/lib';
import {
  SEVERITY,
  STATUS,
} from 'ee/security_orchestration/components/policy_editor/scan_result_policy/scan_filters/constants';
import {
  ANY_OPERATOR,
  MORE_THAN_OPERATOR,
} from 'ee/security_orchestration/components/policy_editor/constants';

describe('SecurityScanRuleBuilder', () => {
  let wrapper;

  const PROTECTED_BRANCHES_MOCK = [{ id: 1, name: 'main' }];

  const UPDATED_RULE = {
    type: SCAN_FINDING,
    branches: [PROTECTED_BRANCHES_MOCK[0].name],
    scanners: ['dast'],
    vulnerabilities_allowed: 1,
    severity_levels: ['high'],
    vulnerability_states: ['newly_detected'],
  };

  const factory = (propsData = {}, provide = {}) => {
    wrapper = mountExtended(SecurityScanRuleBuilder, {
      propsData: {
        initRule: securityScanBuildRule(),
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
  const findVulnAllowedOperator = () => wrapper.findByTestId('vulnerabilities-allowed-operator');
  const findVulnAllowed = () => wrapper.findByTestId('vulnerabilities-allowed-input');
  const findAllPolicyRuleMultiSelect = () => wrapper.findAllComponents(PolicyRuleMultiSelect);
  const findScanFilterSelector = () => wrapper.findComponent(ScanFilterSelector);
  const findStatusFilter = () => wrapper.findComponent(StatusFilter);
  const findSeverityFilter = () => wrapper.findComponent(SeverityFilter);
  const findScanTypeSelect = () => wrapper.findComponent(ScanTypeSelect);

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
      expect(findSeverities().exists()).toBe(false);
      expect(findVulnStates().exists()).toBe(false);
      expect(findVulnAllowedOperator().exists()).toBe(true);
      expect(findVulnAllowed().exists()).toBe(false);
    });

    it('includes select all option to all PolicyRuleMultiSelect', () => {
      const props = findAllPolicyRuleMultiSelect().wrappers.map((w) => w.props());

      expect(props).toEqual(
        expect.arrayContaining([expect.objectContaining({ includeSelectAll: true })]),
      );
    });

    it('does not render branches label when targeting all branches', () => {
      expect(findBranchesLabel().exists()).toBe(false);
    });
  });

  describe('when editing any attribute of the rule', () => {
    it.each`
      currentComponent | newValue                      | expected
      ${findBranches}  | ${PROTECTED_BRANCHES_MOCK[0]} | ${{ branches: UPDATED_RULE.branches }}
      ${findScanners}  | ${UPDATED_RULE.scanners}      | ${{ scanners: UPDATED_RULE.scanners }}
    `(
      'triggers a changed event (by $currentComponent) with the updated rule',
      async ({ currentComponent, newValue, expected }) => {
        factory();
        await nextTick();
        currentComponent().vm.$emit('input', newValue);
        await nextTick();

        expect(wrapper.emitted().changed).toEqual([[expect.objectContaining(expected)]]);
      },
    );
  });

  describe('vulnerabilities allowed', () => {
    it('renders MORE_THAN_OPERATOR when initial vulnerabilities_allowed are not zero', async () => {
      factory({ initRule: { ...UPDATED_RULE, vulnerabilities_allowed: 1 } });
      await nextTick();
      expect(findVulnAllowed().exists()).toBe(true);
      expect(findVulnAllowedOperator().props('selected')).toEqual(MORE_THAN_OPERATOR);
    });

    describe('when editing vulnerabilities allowed', () => {
      beforeEach(async () => {
        factory();
        await nextTick();
      });

      it.each`
        currentComponent   | newValue                                | expected
        ${findVulnAllowed} | ${UPDATED_RULE.vulnerabilities_allowed} | ${{ vulnerabilities_allowed: UPDATED_RULE.vulnerabilities_allowed }}
        ${findVulnAllowed} | ${''}                                   | ${{ vulnerabilities_allowed: 0 }}
      `(
        'triggers a changed event (by $currentComponent) with the updated rule',
        async ({ currentComponent, newValue, expected }) => {
          findVulnAllowedOperator().vm.$emit('select', MORE_THAN_OPERATOR);
          await nextTick();
          currentComponent().vm.$emit('input', newValue);
          await nextTick();

          expect(wrapper.emitted().changed).toEqual([[expect.objectContaining(expected)]]);
        },
      );

      it('resets vulnerabilities_allowed to 0 after changing to ANY_OPERATOR', async () => {
        findVulnAllowedOperator().vm.$emit('select', MORE_THAN_OPERATOR);
        await nextTick();
        findVulnAllowed().vm.$emit('input', 1);
        await nextTick();
        findVulnAllowedOperator().vm.$emit('select', ANY_OPERATOR);
        await nextTick();

        expect(wrapper.emitted().changed).toEqual([
          [expect.objectContaining({ vulnerabilities_allowed: 1 })],
          [expect.objectContaining({ vulnerabilities_allowed: 0 })],
        ]);
      });
    });
  });

  it.each`
    currentComponent  | selectedFilter
    ${findSeverities} | ${SEVERITY}
    ${findVulnStates} | ${STATUS}
  `('select different filters', async ({ currentComponent, selectedFilter }) => {
    factory();
    await findScanFilterSelector().vm.$emit('select', selectedFilter);

    expect(currentComponent().exists()).toBe(true);
  });

  it('renders filters for exiting rule', () => {
    factory({ initRule: UPDATED_RULE });

    expect(findSeverities().exists()).toBe(true);
    expect(findVulnStates().exists()).toBe(true);
  });

  it.each`
    currentComponent      | selectedFilter
    ${findSeverityFilter} | ${SEVERITY}
    ${findStatusFilter}   | ${STATUS}
  `('removes existing filters', async ({ currentComponent, selectedFilter }) => {
    factory();
    await findScanFilterSelector().vm.$emit('select', selectedFilter);
    expect(currentComponent().exists()).toBe(true);

    await currentComponent().vm.$emit('remove', selectedFilter);

    expect(currentComponent().exists()).toBe(false);
    expect(wrapper.emitted('changed')).toHaveLength(1);
  });

  it('does render branches label when a branch is selected', async () => {
    factory({ initRule: UPDATED_RULE });
    await nextTick();
    expect(findBranchesLabel().exists()).toBe(true);
  });

  it('can change scan type', () => {
    factory({ initRule: securityScanBuildRule() });
    findScanTypeSelect().vm.$emit('select', SCAN_FINDING);

    expect(wrapper.emitted('set-scan-type')).toEqual([[getDefaultRule(SCAN_FINDING)]]);
  });
});
