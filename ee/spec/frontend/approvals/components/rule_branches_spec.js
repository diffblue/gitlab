import { shallowMount } from '@vue/test-utils';
import RuleBranches from 'ee/approvals/components/rule_branches.vue';
import {
  ALL_BRANCHES,
  ALL_PROTECTED_BRANCHES,
} from 'ee/vue_shared/components/branches_selector/constants';

describe('Rule Branches', () => {
  let wrapper;

  const defaultProp = {
    rule: {},
  };

  const createComponent = (prop = {}) => {
    wrapper = shallowMount(RuleBranches, {
      propsData: {
        ...defaultProp,
        ...prop,
      },
    });
  };

  const findBranch = () => wrapper.find('div');

  it('displays "All branches" if there are no protected branches', () => {
    createComponent();
    expect(findBranch().text()).toContain(ALL_BRANCHES.name);
    expect(findBranch().classes('monospace')).toBe(false);
  });

  it('displays "All protected branches" if `appliesToAllProtectedBranches` is set to `true`', () => {
    createComponent({ rule: { appliesToAllProtectedBranches: true } });
    expect(findBranch().text()).toContain(ALL_PROTECTED_BRANCHES.name);
    expect(findBranch().classes('monospace')).toBe(false);
  });

  it('displays the branch name of the first protected branch', () => {
    const rule = {
      protectedBranches: [
        {
          id: 1,
          name: 'main',
        },
        {
          id: 2,
          name: 'hello',
        },
      ],
    };

    createComponent({
      rule,
    });

    expect(findBranch().text()).toContain('main');
    expect(findBranch().text()).not.toContain('hello');
    expect(findBranch().classes('monospace')).toBe(true);
  });
});
