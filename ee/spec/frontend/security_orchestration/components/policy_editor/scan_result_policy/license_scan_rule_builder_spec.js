import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import Api from 'ee/api';
import LicenseScanRuleBuilder from 'ee/security_orchestration/components/policy_editor/scan_result_policy/license_scan_rule_builder.vue';
import PolicyRuleBranchSelection from 'ee/security_orchestration/components/policy_editor/scan_result_policy/policy_rule_branch_selection.vue';
import PolicyRuleMultiSelect from 'ee/security_orchestration/components/policy_rule_multi_select.vue';
import StatusFilter from 'ee/security_orchestration/components/policy_editor/scan_result_policy/scan_filters/status_filter.vue';
import ScanFilterSelector from 'ee/security_orchestration/components/policy_editor/scan_result_policy/scan_filters/scan_filter_selector.vue';
import { STATUS } from 'ee/security_orchestration/components/policy_editor/scan_result_policy/scan_filters/constants';
import ScanTypeSelect from 'ee/security_orchestration/components/policy_editor/scan_result_policy/base_layout/scan_type_select.vue';
import {
  SCAN_FINDING,
  getDefaultRule,
} from 'ee/security_orchestration/components/policy_editor/scan_result_policy/lib';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';

describe('LicenseScanRuleBuilder', () => {
  let wrapper;

  const PROTECTED_BRANCHES_MOCK = [{ id: 1, name: 'main' }];

  const DEFAULT_RULE = {
    type: 'license_finding',
    branches: [],
    match_on_inclusion: null,
    license_types: [],
    license_states: [],
  };

  const UPDATED_RULE = {
    type: 'license_finding',
    branches: [PROTECTED_BRANCHES_MOCK[0].name],
    match_on_inclusion: true,
    license_types: ['MIT', 'BSD'],
    license_states: ['newly_detected', 'detected'],
  };

  const factory = (propsData = {}, provide = {}) => {
    wrapper = mountExtended(LicenseScanRuleBuilder, {
      propsData: {
        initRule: DEFAULT_RULE,
        ...propsData,
      },
      provide: {
        namespaceId: '1',
        namespaceType: NAMESPACE_TYPES.PROJECT,
        softwareLicenses: '[]',
        ...provide,
      },
      stubs: {
        PolicyRuleBranchSelection: true,
      },
    });
  };

  const findBranches = () => wrapper.findComponent(PolicyRuleBranchSelection);
  const findGroupLevelBranches = () => wrapper.findByTestId('group-level-branch');
  const findMatchType = () => wrapper.findByTestId('match-type-select');
  const findLicenseStates = () => wrapper.findByTestId('license-state-select');
  const findLicenseMultiSelect = () => wrapper.findByTestId('license-multi-select');
  const findAllPolicyRuleMultiSelect = () => wrapper.findAllComponents(PolicyRuleMultiSelect);
  const findScanFilterSelector = () => wrapper.findComponent(ScanFilterSelector);
  const findStatusFilter = () => wrapper.findComponent(StatusFilter);
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
      expect(findMatchType().exists()).toBe(true);
      expect(findLicenseStates().exists()).toBe(true);
      expect(findLicenseMultiSelect().exists()).toBe(true);
    });

    it('includes select all option to all PolicyRuleMultiSelect', async () => {
      await findScanFilterSelector().vm.$emit('select', STATUS);
      const props = findAllPolicyRuleMultiSelect().wrappers.map((w) => w.props());

      expect(props).toEqual(
        expect.arrayContaining([expect.objectContaining({ includeSelectAll: true })]),
      );
    });
  });

  describe('when editing any attribute of the rule', () => {
    it.each`
      currentComponent          | newValue                                           | expected                                                   | event
      ${findBranches}           | ${{ branches: [PROTECTED_BRANCHES_MOCK[0].name] }} | ${{ branches: UPDATED_RULE.branches }}                     | ${'changed'}
      ${findMatchType}          | ${UPDATED_RULE.match_on_inclusion}                 | ${{ match_on_inclusion: UPDATED_RULE.match_on_inclusion }} | ${'select'}
      ${findLicenseMultiSelect} | ${UPDATED_RULE.license_types}                      | ${{ license_types: UPDATED_RULE.license_types }}           | ${'select'}
    `(
      'triggers a changed event (by $currentComponent) with the updated rule',
      async ({ currentComponent, newValue, expected, event }) => {
        factory();
        await nextTick();
        await currentComponent().vm.$emit(event, newValue);

        expect(wrapper.emitted().changed).toEqual([[expect.objectContaining(expected)]]);
      },
    );
  });

  describe('additional filter criteria', () => {
    beforeEach(async () => {
      factory();
      await findScanFilterSelector().vm.$emit('select', STATUS);
    });

    it('should select status filter', () => {
      expect(findStatusFilter().exists()).toBe(true);
    });

    it('should select status', async () => {
      await findLicenseStates().vm.$emit('input', 'Newly Detected');
      expect(wrapper.emitted('changed')).toEqual([
        [expect.objectContaining({ license_states: 'Newly Detected' })],
      ]);
    });
  });

  it('can change scan type', () => {
    factory({ initRule: DEFAULT_RULE });
    findScanTypeSelect().vm.$emit('select', SCAN_FINDING);

    expect(wrapper.emitted('set-scan-type')).toEqual([[getDefaultRule(SCAN_FINDING)]]);
  });
});
