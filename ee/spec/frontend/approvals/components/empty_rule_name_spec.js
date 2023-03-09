import { GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import EmptyRuleName from 'ee/approvals/components/empty_rule_name.vue';

describe('Empty Rule Name', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(EmptyRuleName, {
      propsData: {
        rule: {},
        eligibleApproversDocsPath: 'some/path',
        ...props,
      },
    });
  };

  it('has a rule name "All eligible users"', () => {
    createComponent();

    expect(wrapper.text()).toContain('All eligible users');
  });

  it('renders a "more information" link', () => {
    createComponent();

    expect(wrapper.findComponent(GlLink).attributes('href')).toBe(
      wrapper.props('eligibleApproversDocsPath'),
    );
    expect(wrapper.findComponent(GlLink).exists()).toBe(true);
    expect(wrapper.findComponent(GlLink).text()).toBe('More information');
  });
});
