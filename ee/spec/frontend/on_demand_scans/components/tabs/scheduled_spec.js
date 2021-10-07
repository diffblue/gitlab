import { shallowMount } from '@vue/test-utils';
import ScheduledTab from 'ee/on_demand_scans/components/tabs/scheduled.vue';
import BaseTab from 'ee/on_demand_scans/components/tabs/base_tab.vue';

describe('ScheduledTab', () => {
  let wrapper;

  // Finders
  const findBaseTab = () => wrapper.findComponent(BaseTab);

  const createComponent = (propsData) => {
    wrapper = shallowMount(ScheduledTab, {
      propsData,
    });
  };

  beforeEach(() => {
    createComponent({
      itemCount: 12,
    });
  });

  it('renders the base tab with the correct props', () => {
    expect(findBaseTab().props('title')).toBe('Scheduled');
    expect(findBaseTab().props('itemCount')).toBe(12);
    expect(findBaseTab().props('emptyStateTitle')).toBe(wrapper.vm.$options.i18n.emptyStateTitle);
    expect(findBaseTab().props('emptyStateText')).toBe(wrapper.vm.$options.i18n.emptyStateText);
  });
});
