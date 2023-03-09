import { GlIcon, GlButton } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import ScanResultPolicy from 'ee/approvals/components/security_orchestration/scan_result_policy.vue';

describe('ScanResultPolicy', () => {
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

  const factory = (policy = {}, mountFc = shallowMount) => {
    wrapper = mountFc(ScanResultPolicy, {
      propsData: {
        policy: {
          ...initialPolicy,
          ...policy,
        },
      },
    });
  };

  const findIcon = () => wrapper.findComponent(GlIcon);
  const findButton = () => wrapper.findComponent(GlButton);

  beforeEach(() => {
    factory();
  });

  it('renders policy name, branches and the number of approvals required', () => {
    const text = wrapper.text();

    expect(text).toContain('test policy');
    expect(text).toContain('All protected branches');
    expect(text).toContain('1');
  });

  describe('with a single branch', () => {
    beforeEach(() => {
      factory({
        rules: [
          {
            type: 'scan_finding',
            branches: ['main'],
            scanners: [],
            vulnerabilities_allowed: 0,
            severity_levels: ['critical'],
            vulnerability_states: ['newly_detected'],
          },
        ],
      });
    });

    it('renders the specific branch name', () => {
      const expectedPolicyText = 'main';

      expect(wrapper.text()).toContain(expectedPolicyText);
    });
  });

  describe('with isSelected set to true', () => {
    it('renders the view details button with expanded related icon', () => {
      expect(findIcon().props('name')).toBe('chevron-up');
      expect(findButton().text()).toBe('View details');
    });
  });

  describe('with isSelected set to false', () => {
    beforeEach(() => {
      factory({ isSelected: false });
    });

    it('renders the view details button with collapsed related icon', () => {
      expect(findIcon().props('name')).toBe('chevron-down');
      expect(findButton().text()).toBe('View details');
    });
  });

  describe('when view details button is clicked', () => {
    beforeEach(() => {
      factory({ isSelected: false }, mount);
    });

    it('triggers a toggle event', async () => {
      await findButton().trigger('click');

      expect(wrapper.emitted('toggle')).toHaveLength(1);
    });
  });
});
