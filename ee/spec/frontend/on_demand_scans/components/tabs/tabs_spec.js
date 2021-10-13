import { shallowMount } from '@vue/test-utils';
import RunningTab from 'ee/on_demand_scans/components/tabs/running.vue';
import FinishedTab from 'ee/on_demand_scans/components/tabs/finished.vue';
import ScheduledTab from 'ee/on_demand_scans/components/tabs/scheduled.vue';
import BaseTab from 'ee/on_demand_scans/components/tabs/base_tab.vue';

describe.each`
  title          | component
  ${'Running'}   | ${RunningTab}
  ${'Finished'}  | ${FinishedTab}
  ${'Scheduled'} | ${ScheduledTab}
`('$title tab', ({ title, component }) => {
  let wrapper;

  // Props
  const itemCount = 12;

  // Finders
  const findBaseTab = () => wrapper.findComponent(BaseTab);

  const createComponent = (propsData) => {
    wrapper = shallowMount(component, {
      propsData,
    });
  };

  beforeEach(() => {
    createComponent({
      itemCount,
    });
  });

  it('renders the base tab with the correct props', () => {
    expect(findBaseTab().props('title')).toBe(title);
    expect(findBaseTab().props('itemCount')).toBe(itemCount);
    expect(findBaseTab().props('emptyStateTitle')).toBe(wrapper.vm.$options.i18n.emptyStateTitle);
    expect(findBaseTab().props('emptyStateText')).toBe(wrapper.vm.$options.i18n.emptyStateText);
  });
});
