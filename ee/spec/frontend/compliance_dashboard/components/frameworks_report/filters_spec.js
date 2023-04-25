import { mount } from '@vue/test-utils';
import { GlPopover, GlFilteredSearch, GlButton } from '@gitlab/ui';
import ComplianceFrameworksFilters from 'ee/compliance_dashboard/components/frameworks_report/filters.vue';

describe('ComplianceFrameworksFilters', () => {
  let wrapper;

  const findFilteredSearch = () => wrapper.findComponent(GlFilteredSearch);

  const value = [];

  const createComponent = (props) => {
    wrapper = mount(ComplianceFrameworksFilters, {
      propsData: {
        value,
        rootAncestorPath: 'my-group-path',
        ...props,
      },
      stubs: {
        GlFilteredSearch: true,
      },
    });
  };

  describe('when showUpdatePopover is false', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders a Filtered Search component with correct props', () => {
      expect(findFilteredSearch().exists()).toBe(true);
      expect(wrapper.props('rootAncestorPath')).toBe('my-group-path');
      expect(findFilteredSearch().props('placeholder')).toBe('Search or filter results');
    });

    it('emits a "submit" event with the filters when Filtered Search component is submitted', () => {
      findFilteredSearch().vm.$emit('submit', { framework: 'my-framework' });

      expect(wrapper.emitted('submit')).toEqual([[{ framework: 'my-framework' }]]);
    });

    it('does not show update popover by default', () => {
      expect(wrapper.findComponent(GlPopover).props('show')).toBe(false);
    });
  });

  describe('when showUpdatePopover is true', () => {
    beforeEach(() => {
      createComponent({ showUpdatePopover: true });
    });
    it('shows update popover when showUpdatePopover is true', () => {
      expect(wrapper.findComponent(GlPopover).props('show')).toBe(true);
    });

    it('emits submit on primary popover action', () => {
      const primaryButton = wrapper
        .findComponent(GlPopover)
        .findAllComponents(GlButton)
        .wrappers.find((w) => w.props('category') === 'primary');

      primaryButton.vm.$emit('click');
      expect(wrapper.emitted('submit').at(-1)).toStrictEqual([value]);
    });
  });
});
