import { shallowMount } from '@vue/test-utils';
import RuleBranches from 'ee/approvals/components/rule_branches.vue';

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

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findBranch = () => wrapper.find('div');

  it('displays "All branches" if there are no protected branches', () => {
    createComponent();
    expect(findBranch().text()).toContain('All branches');
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
