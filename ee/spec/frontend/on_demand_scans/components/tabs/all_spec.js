import { shallowMount } from '@vue/test-utils';
import AllTab from 'ee/on_demand_scans/components/tabs/all.vue';
import BaseTab from 'ee/on_demand_scans/components/tabs/base_tab.vue';

describe('AllTab', () => {
  let wrapper;

  // Finders
  const findBaseTab = () => wrapper.findComponent(BaseTab);

  const createComponent = (propsData) => {
    wrapper = shallowMount(AllTab, {
      propsData,
    });
  };

  beforeEach(() => {
    createComponent({
      itemsCount: 12,
    });
  });

  it('renders the base tab with the correct props', () => {
    expect(findBaseTab().props('title')).toBe('All');
    expect(findBaseTab().props('itemsCount')).toBe(12);
    expect(findBaseTab().props('fields')).toMatchSnapshot();
  });
});
