import { GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import PolicyDetails from 'ee/approvals/components/security_orchestration/policy_details.vue';
import RequestApprovals from 'ee/security_orchestration/components/policy_drawer/require_approvals.vue';

describe('PolicyDetails', () => {
  let wrapper;

  const initialPolicy = {
    name: 'test policy/test approval',
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
    approvers: [{ __typename: 'UserCore', id: 1, name: 'name' }],
    source: {
      project: {
        fullPath: 'policy/path',
      },
    },
  };

  const factory = (policyData = {}) => {
    wrapper = shallowMount(PolicyDetails, {
      propsData: {
        policy: {
          ...initialPolicy,
          ...policyData,
        },
      },
    });
  };

  const findLink = () => wrapper.findComponent(GlLink);
  const findRequiredApprovals = () => wrapper.findComponent(RequestApprovals);

  describe('with isSelected set to true', () => {
    beforeEach(() => {
      factory();
    });

    it('renders the text version of the related action and each of the rules', () => {
      const text = wrapper.text();
      expect(findRequiredApprovals().exists()).toBe(true);
      expect(text).toContain('When any security scanner');
      expect(text).toContain('critical');
    });

    it('renders a link to policy path', () => {
      const policyPath = `/policy/path/-/security/policies/${encodeURIComponent(
        initialPolicy.name,
      )}/edit?type=scan_result_policy`;

      expect(findLink().attributes('href')).toBe(policyPath);
    });

    describe('with an inherited policy', () => {
      beforeEach(() => {
        factory({ source: { inherited: true, namespace: { fullPath: 'policy/path' } } });
      });

      it('renders a link to policy path', () => {
        const policyPath = `/groups/policy/path/-/security/policies/${encodeURIComponent(
          initialPolicy.name,
        )}/edit?type=scan_result_policy`;

        expect(findLink().attributes('href')).toBe(policyPath);
      });
    });
  });

  describe('with isSelected set to false', () => {
    beforeEach(() => {
      factory({ isSelected: false });
    });

    it('does not render a text based on action and rules', () => {
      expect(wrapper.text()).toBe('');
      expect(findRequiredApprovals().exists()).toBe(false);
    });

    it('does not render a link to the policy path', () => {
      expect(findLink().exists()).toBe(false);
    });
  });
});
