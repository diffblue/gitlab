import { mount } from '@vue/test-utils';
import { GlFilteredSearch } from '@gitlab/ui';
import ComplianceFrameworksFilters from 'ee/compliance_dashboard/components/frameworks_report/filters.vue';

describe('ComplianceFrameworksFilters', () => {
  let wrapper;

  const findFilteredSearch = () => wrapper.findComponent(GlFilteredSearch);

  beforeEach(() => {
    wrapper = mount(ComplianceFrameworksFilters, {
      propsData: {
        value: [],
        rootAncestorPath: 'my-group-path',
      },
      stubs: {
        GlFilteredSearch: true,
      },
    });
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
});
