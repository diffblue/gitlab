import { shallowMount } from '@vue/test-utils';
import OnDemandScans from 'ee/on_demand_scans/components/on_demand_scans.vue';
import EmptyState from 'ee/on_demand_scans/components/empty_state.vue';

describe('OnDemandScans', () => {
  let wrapper;

  // Finders
  const findEmptyState = () => wrapper.findComponent(EmptyState);

  const createComponent = () => {
    wrapper = shallowMount(OnDemandScans);
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders an empty state', () => {
    createComponent();

    expect(findEmptyState().exists()).toBe(true);
  });
});
