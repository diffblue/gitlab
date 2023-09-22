import { nextTick } from 'vue';
import { GlBadge } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import Api from 'ee/api';
import BranchExceptionSelector from 'ee/security_orchestration/components/policy_editor/branch_exception_selector.vue';
import SecurityScanRuleBuilder from 'ee/security_orchestration/components/policy_editor/scan_result/rule/security_scan_rule_builder.vue';
import RuleMultiSelect from 'ee/security_orchestration/components/policy_editor/rule_multi_select.vue';
import BranchSelection from 'ee/security_orchestration/components/policy_editor/scan_result/rule/branch_selection.vue';
import SeverityFilter from 'ee/security_orchestration/components/policy_editor/scan_result/rule/scan_filters/severity_filter.vue';
import StatusFilter from 'ee/security_orchestration/components/policy_editor/scan_result/rule/scan_filters/status_filter.vue';
import AgeFilter from 'ee/security_orchestration/components/policy_editor/scan_result/rule/scan_filters/age_filter.vue';
import AttributeFilters from 'ee/security_orchestration/components/policy_editor/scan_result/rule/scan_filters/attribute_filters.vue';
import ScanTypeSelect from 'ee/security_orchestration/components/policy_editor/scan_result/rule/scan_type_select.vue';
import ScanFilterSelector from 'ee/security_orchestration/components/policy_editor/scan_filter_selector.vue';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';
import { SEVERITY_LEVELS } from 'ee/security_dashboard/store/constants';
import {
  securityScanBuildRule,
  SCAN_FINDING,
} from 'ee/security_orchestration/components/policy_editor/scan_result/lib/rules';
import { getDefaultRule } from 'ee/security_orchestration/components/policy_editor/scan_result/lib';
import {
  SEVERITY,
  STATUS,
  NEWLY_DETECTED,
  PREVIOUSLY_EXISTING,
  AGE,
  AGE_DAY,
  ATTRIBUTE,
  FALSE_POSITIVE,
} from 'ee/security_orchestration/components/policy_editor/scan_result/rule/scan_filters/constants';
import {
  ANY_OPERATOR,
  GREATER_THAN_OPERATOR,
  LESS_THAN_OPERATOR,
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
    vulnerability_states: ['detected'],
    vulnerability_age: { interval: AGE_DAY, value: 1, operator: LESS_THAN_OPERATOR },
    vulnerability_attributes: { [FALSE_POSITIVE]: false },
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
        namespacePath: 'gitlab-org/test',
        glFeatures: {
          securityPoliciesBranchExceptions: true,
        },
        ...provide,
      },
      stubs: {
        BranchSelection: true,
      },
    });
  };

  const findBranches = () => wrapper.findComponent(BranchSelection);
  const findGroupLevelBranches = () => wrapper.findByTestId('group-level-branch');
  const findScanners = () => wrapper.findByTestId('scanners-select');
  const findSeverities = () => wrapper.findByTestId('severities-select');
  const findVulnStates = () => wrapper.findByTestId('vulnerability-states-select');
  const findVulnAllowedOperator = () => wrapper.findByTestId('vulnerabilities-allowed-operator');
  const findVulnAllowed = () => wrapper.findByTestId('vulnerabilities-allowed-input');
  const findAllPolicyRuleMultiSelect = () => wrapper.findAllComponents(RuleMultiSelect);
  const findScanFilterSelector = () => wrapper.findComponent(ScanFilterSelector);
  const findStatusFilter = () => wrapper.findComponent(StatusFilter);
  const findSeverityFilter = () => wrapper.findComponent(SeverityFilter);
  const findAllStatusFilters = () => wrapper.findAllComponents(StatusFilter);
  const findAttributeFilters = () => wrapper.findComponent(AttributeFilters);
  const findScanTypeSelect = () => wrapper.findComponent(ScanTypeSelect);
  const findAgeFilter = () => wrapper.findComponent(AgeFilter);
  const findScanFilterSelectorBadge = () => findScanFilterSelector().findComponent(GlBadge);
  const findBranchExceptionSelector = () => wrapper.findComponent(BranchExceptionSelector);

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
      expect(findVulnAllowedOperator().exists()).toBe(true);
      expect(findVulnAllowed().exists()).toBe(false);
      expect(findAttributeFilters().exists()).toBe(false);
    });

    it('includes select all option to all PolicyRuleMultiSelect', () => {
      const props = findAllPolicyRuleMultiSelect().wrappers.map((w) => w.props());

      expect(props).toEqual(
        expect.arrayContaining([expect.objectContaining({ includeSelectAll: true })]),
      );
    });
  });

  describe('adding branch exceptions', () => {
    const exceptions = { branch_exceptions: ['main', 'test'] };

    it.each`
      namespaceType              | expectedResult
      ${NAMESPACE_TYPES.PROJECT} | ${true}
      ${NAMESPACE_TYPES.GROUP}   | ${false}
    `('should select exceptions only on project level', ({ namespaceType, expectedResult }) => {
      factory(
        {},
        {
          namespaceType,
        },
      );

      expect(findBranchExceptionSelector().exists()).toBe(expectedResult);
    });

    it('should select exceptions', () => {
      factory();

      findBranchExceptionSelector().vm.$emit('select', exceptions);

      expect(wrapper.emitted('changed')).toEqual([
        [
          {
            ...securityScanBuildRule(),
            ...exceptions,
          },
        ],
      ]);
    });

    it('should display saved exceptions', () => {
      factory({
        initRule: {
          ...securityScanBuildRule(),
          ...exceptions,
        },
      });

      expect(findBranchExceptionSelector().props('selectedExceptions')).toEqual(
        exceptions.branch_exceptions,
      );
    });

    it('should remove selection from rule', () => {
      factory({
        initRule: {
          ...securityScanBuildRule(),
          ...exceptions,
        },
      });

      findBranchExceptionSelector().vm.$emit('remove');

      expect(wrapper.emitted('changed')).toEqual([
        [
          {
            ...securityScanBuildRule(),
          },
        ],
      ]);
    });
  });

  describe('when editing any attribute of the rule', () => {
    it.each`
      currentComponent | event        | newValue                                           | expected
      ${findBranches}  | ${'changed'} | ${{ branches: [PROTECTED_BRANCHES_MOCK[0].name] }} | ${{ branches: UPDATED_RULE.branches }}
      ${findScanners}  | ${'input'}   | ${UPDATED_RULE.scanners}                           | ${{ scanners: UPDATED_RULE.scanners }}
    `(
      'triggers a changed event (by $currentComponent) with the updated rule',
      async ({ currentComponent, event, newValue, expected }) => {
        factory();
        await nextTick();
        currentComponent().vm.$emit(event, newValue);
        await nextTick();

        expect(wrapper.emitted().changed).toEqual([[expect.objectContaining(expected)]]);
      },
    );
  });

  describe('vulnerabilities allowed', () => {
    it('renders GREATER_THAN_OPERATOR when initial vulnerabilities_allowed are not zero', async () => {
      factory({ initRule: { ...UPDATED_RULE, vulnerabilities_allowed: 1 } });
      await nextTick();
      expect(findVulnAllowed().exists()).toBe(true);
      expect(findVulnAllowedOperator().props('selected')).toEqual(GREATER_THAN_OPERATOR);
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
          findVulnAllowedOperator().vm.$emit('select', GREATER_THAN_OPERATOR);
          await nextTick();
          currentComponent().vm.$emit('input', newValue);
          await nextTick();

          expect(wrapper.emitted().changed).toEqual([[expect.objectContaining(expected)]]);
        },
      );

      it('resets vulnerabilities_allowed to 0 after changing to ANY_OPERATOR', async () => {
        findVulnAllowedOperator().vm.$emit('select', GREATER_THAN_OPERATOR);
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
    currentComponent        | selectedFilter | existingFilters                           | expectedExists
    ${findSeverities}       | ${SEVERITY}    | ${{}}                                     | ${true}
    ${findVulnStates}       | ${STATUS}      | ${{}}                                     | ${true}
    ${findAgeFilter}        | ${AGE}         | ${{}}                                     | ${false}
    ${findAgeFilter}        | ${AGE}         | ${{ vulnerability_states: ['detected'] }} | ${true}
    ${findAttributeFilters} | ${ATTRIBUTE}   | ${{}}                                     | ${true}
  `(
    'select $selectedFilter filter',
    async ({ currentComponent, selectedFilter, existingFilters, expectedExists }) => {
      factory({ initRule: { ...securityScanBuildRule(), ...existingFilters } });
      await findScanFilterSelector().vm.$emit('select', selectedFilter);

      expect(currentComponent().exists()).toBe(expectedExists);
    },
  );

  it('selects the correct filters', () => {
    factory({ initRule: UPDATED_RULE });

    expect(findScanFilterSelector().props('selected')).toEqual({
      age: true,
      previously_existing: true,
      newly_detected: false,
      status: false,
      false_positive: true,
      fix_available: false,
      attribute: false,
    });
  });

  describe('severity filter', () => {
    const severityLevels = Object.keys(SEVERITY_LEVELS);

    describe('displaying values', () => {
      it('displays selected scanners', () => {
        const selectedLevel = ['critical'];
        factory({ initRule: { ...securityScanBuildRule(), severity_levels: selectedLevel } });
        expect(findSeverityFilter().props('selected')).toEqual(selectedLevel);
      });

      it('displays all values if the property is an empty array', () => {
        factory();
        expect(findSeverityFilter().props('selected')).toEqual(severityLevels);
      });

      it('displays all values if the property does not exist', () => {
        const initRuleWithoutSeverityLevels = {
          ...securityScanBuildRule(),
        };
        delete initRuleWithoutSeverityLevels.severity_levels;
        factory({ initRule: initRuleWithoutSeverityLevels });
        expect(findSeverityFilter().props('selected')).toEqual(severityLevels);
      });

      it('displays no values if the property is null', () => {
        factory({ initRule: { ...securityScanBuildRule(), severity_levels: null } });
        expect(findSeverityFilter().props('selected')).toEqual([]);
      });
    });

    describe('updating value', () => {
      it('sets selected values', async () => {
        const selectedLevel = ['high'];
        factory();
        await findSeverityFilter().vm.$emit('input', selectedLevel);
        expect(wrapper.emitted('changed')).toEqual([
          [expect.objectContaining({ severity_levels: selectedLevel })],
        ]);
      });

      it('sets an empty array if all items are selected', async () => {
        factory();
        await findSeverityFilter().vm.$emit('input', severityLevels);
        expect(wrapper.emitted('changed')).toEqual([
          [expect.objectContaining({ severity_levels: [] })],
        ]);
      });
    });
  });

  describe('status filter', () => {
    it('renders new filter if `null` value is provided in vulnerability_states', () => {
      factory({ initRule: { ...UPDATED_RULE, vulnerability_states: null } });

      expect(findAllStatusFilters()).toHaveLength(1);
      expect(findStatusFilter().props('filter')).toEqual(NEWLY_DETECTED);
      expect(findScanFilterSelector().props('selected')).toEqual(
        expect.objectContaining({
          previously_existing: false,
          newly_detected: true,
        }),
      );
    });

    it('can change the status group', async () => {
      factory({ initRule: { ...UPDATED_RULE, vulnerability_states: [] } });

      expect(findAllStatusFilters()).toHaveLength(1);
      expect(findStatusFilter().props('filter')).toEqual(NEWLY_DETECTED);
      await findStatusFilter().vm.$emit('change-group', PREVIOUSLY_EXISTING);
      expect(findStatusFilter().props('filter')).toEqual(PREVIOUSLY_EXISTING);
    });

    it('can add and remove second status filter', async () => {
      factory({ initRule: UPDATED_RULE });

      await findScanFilterSelector().vm.$emit('select', STATUS);

      const statusFilters = findAllStatusFilters();

      expect(statusFilters).toHaveLength(2);
      expect(statusFilters.at(0).props('filter')).toEqual(NEWLY_DETECTED);
      expect(statusFilters.at(1).props('filter')).toEqual(PREVIOUSLY_EXISTING);
      expect(findScanFilterSelector().props('selected')).toEqual({
        age: true,
        previously_existing: true,
        newly_detected: true,
        status: true,
        false_positive: true,
        fix_available: false,
        attribute: false,
      });

      await statusFilters.at(1).vm.$emit('remove', NEWLY_DETECTED);

      expect(findScanFilterSelector().props('selected')).toEqual({
        age: true,
        newly_detected: false,
        previously_existing: true,
        status: false,
        false_positive: true,
        fix_available: false,
        attribute: false,
      });
    });
  });

  it('renders filters for exiting rule', () => {
    factory({ initRule: UPDATED_RULE });

    expect(findSeverities().exists()).toBe(true);
    expect(findVulnStates().exists()).toBe(true);
    expect(findAgeFilter().exists()).toBe(true);
  });

  it.each`
    currentComponent        | selectedFilter         | existingFilters
    ${findStatusFilter}     | ${NEWLY_DETECTED}      | ${{}}
    ${findStatusFilter}     | ${PREVIOUSLY_EXISTING} | ${{ vulnerability_states: ['detected'] }}
    ${findAgeFilter}        | ${AGE}                 | ${{ vulnerability_states: ['detected'] }}
    ${findAttributeFilters} | ${ATTRIBUTE}           | ${{}}
  `(
    'removes existing $selectedFilter filter',
    async ({ currentComponent, selectedFilter, existingFilters }) => {
      factory({ initRule: { ...securityScanBuildRule(), ...existingFilters } });
      await findScanFilterSelector().vm.$emit('select', selectedFilter);
      expect(currentComponent().exists()).toBe(true);

      const emittedCountBeforeRemove = (wrapper.emitted('changed') || []).length;

      await currentComponent().vm.$emit('remove', selectedFilter);

      expect(currentComponent().exists()).toBe(false);
      expect(wrapper.emitted('changed')).toHaveLength(emittedCountBeforeRemove + 1);
    },
  );

  describe('age filter specific behavior in combination with previously existing filter', () => {
    it('shows badge on scan filter selector with no previously existing filter', () => {
      factory({ initRule: securityScanBuildRule() });

      expect(findScanFilterSelectorBadge().attributes('title')).toEqual(
        'Age criteria can only be added for pre-existing vulnerabilities',
      );
    });

    it('has no the badge on scan filter selector with previously existing filter', async () => {
      factory({ initRule: { ...securityScanBuildRule(), vulnerability_states: ['detected'] } });

      expect(findScanFilterSelectorBadge().exists()).toBe(false);

      await findScanFilterSelector().vm.$emit('select', AGE);

      expect(findScanFilterSelectorBadge().attributes('title')).toEqual(
        'Only 1 age criteria is allowed',
      );

      await findAgeFilter().vm.$emit('input', {
        operator: GREATER_THAN_OPERATOR,
        value: 1,
        interval: AGE_DAY,
      });
      expect(wrapper.emitted('changed')).toHaveLength(1);
    });

    it('removes age filter when there is no previously existing filter', async () => {
      factory({
        initRule: UPDATED_RULE,
      });

      await wrapper.setProps({
        initRule: { ...UPDATED_RULE, vulnerability_states: [] },
      });
      await findStatusFilter().vm.$emit('change-group', NEWLY_DETECTED);

      expect(findAgeFilter().exists()).toBe(false);
      expect(wrapper.emitted('changed')).toHaveLength(2);
    });
  });

  const updatedRuleWithoutFilter = (filter) => {
    const { [filter]: deletedFilter, ...rule } = UPDATED_RULE;
    return rule;
  };

  it.each`
    currentComponent        | selectedFilter         | emittedPayload
    ${findStatusFilter}     | ${PREVIOUSLY_EXISTING} | ${{ ...UPDATED_RULE, vulnerability_states: null }}
    ${findAgeFilter}        | ${AGE}                 | ${updatedRuleWithoutFilter('vulnerability_age')}
    ${findAttributeFilters} | ${FALSE_POSITIVE}      | ${updatedRuleWithoutFilter('vulnerability_attributes')}
  `(
    'removes existing filters for saved policies',
    ({ currentComponent, selectedFilter, emittedPayload }) => {
      factory({
        initRule: UPDATED_RULE,
      });

      expect(currentComponent().exists()).toBe(true);

      currentComponent().vm.$emit('remove', selectedFilter);

      expect(wrapper.emitted('changed')).toEqual([[emittedPayload]]);
    },
  );

  it('can change scan type', () => {
    factory({ initRule: securityScanBuildRule() });
    findScanTypeSelect().vm.$emit('select', SCAN_FINDING);

    expect(wrapper.emitted('set-scan-type')).toEqual([[getDefaultRule(SCAN_FINDING)]]);
  });

  describe('disabled feature flag', () => {
    it('should not render branch exceptions when feature flag is disabled', () => {
      factory(
        {},
        {
          glFeatures: {
            securityPoliciesBranchExceptions: false,
          },
        },
      );

      expect(findBranchExceptionSelector().exists()).toBe(false);
    });
  });
});
