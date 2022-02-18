import { mount } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import { nextTick } from 'vue';
import Api from 'ee/api';
import PolicyRuleBuilder from 'ee/threat_monitoring/components/policy_editor/scan_result_policy/policy_rule_builder.vue';
import ProtectedBranchesSelector from 'ee/vue_shared/components/branches_selector/protected_branches_selector.vue';

describe('PolicyRuleBuilder', () => {
  let wrapper;

  const PROTECTED_BRANCHES_MOCK = [{ id: 1, name: 'main' }];

  const DEFAULT_RULE = {
    type: 'scan_finding',
    branches: [PROTECTED_BRANCHES_MOCK[0].name],
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

  const factory = (propsData = {}) => {
    wrapper = mount(PolicyRuleBuilder, {
      propsData: {
        initRule: DEFAULT_RULE,
        ...propsData,
      },
      provide: {
        projectId: '1',
      },
    });
  };

  const findBranches = () => wrapper.findComponent(ProtectedBranchesSelector);
  const findScanners = () => wrapper.find('[data-testid="scanners-select"]');
  const findSeverities = () => wrapper.find('[data-testid="severities-select"]');
  const findVulnStates = () => wrapper.find('[data-testid="vulnerability-states-select"]');
  const findVulnAllowed = () => wrapper.find('[data-testid="vulnerabilities-allowed-input"]');
  const findDeleteBtn = () => wrapper.findComponent(GlButton);

  beforeEach(() => {
    jest
      .spyOn(Api, 'projectProtectedBranches')
      .mockReturnValue(Promise.resolve(PROTECTED_BRANCHES_MOCK));
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('initial rendering', () => {
    it('renders one field for each attribute of the rule', async () => {
      factory();
      await nextTick();

      expect(findBranches().exists()).toBe(true);
      expect(findScanners().exists()).toBe(true);
      expect(findSeverities().exists()).toBe(true);
      expect(findVulnStates().exists()).toBe(true);
      expect(findVulnAllowed().exists()).toBe(true);
    });

    it('renders the delete buttom', async () => {
      factory();
      await nextTick();

      expect(findDeleteBtn().exists()).toBe(true);
    });
  });

  describe('when removing the rule', () => {
    it('emits remove event', async () => {
      factory();
      await nextTick();
      await findDeleteBtn().vm.$emit('click');

      expect(wrapper.emitted().remove).toHaveLength(1);
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
});
