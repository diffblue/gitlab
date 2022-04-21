import { GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import PolicyDetails from 'ee/approvals/components/security_orchestration/policy_details.vue';

const SECURITY_POLICY_PATH = 'policy/path';

describe('PolicyDetails', () => {
  let wrapper;

  const initialPolicy = {
    name: 'test policy',
    isSelected: true,
    rules: [
      {
        type: 'scan_finding',
        branches: [],
        scanners: [],
        vulnerabilities_allowed: 0,
        severity_levels: ['critical'],
        vulnerability_states: ['newly_detected'],
      },
    ],
    actions: [{ type: 'require_approval', approvals_required: 1, user_approvers: ['admin'] }],
  };

  const factory = (policyData = {}) => {
    wrapper = shallowMount(PolicyDetails, {
      propsData: {
        policy: {
          ...initialPolicy,
          ...policyData,
        },
      },
      provide: {
        securityPoliciesPath: SECURITY_POLICY_PATH,
      },
    });
  };

  const findLink = () => wrapper.findComponent(GlLink);

  describe('with isSelected set to true', () => {
    beforeEach(() => {
      factory();
    });

    it('renders the text version of the related action and each of the rules', () => {
      const text = wrapper.text();

      expect(text).toContain('1 approval');
      expect(text).toContain('admin');
      expect(text).toContain('Any scanner');
      expect(text).toContain('critical vulnerability');
    });

    it('renders a link to policy path', () => {
      const policyPath = 'policy/path/test policy/edit?type=scan_result_policy';

      expect(findLink().attributes('href')).toBe(policyPath);
    });
  });

  describe('with isSelected set to false', () => {
    beforeEach(() => {
      factory({ isSelected: false });
    });

    it('does not render a text based on action and rules', () => {
      expect(wrapper.text()).toBe('');
    });

    it('does not render a link to the policy path', () => {
      expect(findLink().exists()).toBe(false);
    });
  });
});
