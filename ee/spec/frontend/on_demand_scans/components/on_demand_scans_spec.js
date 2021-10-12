import { shallowMount } from '@vue/test-utils';
import { GlTabs } from '@gitlab/ui';
import OnDemandScans from 'ee/on_demand_scans/components/on_demand_scans.vue';
import { createRouter } from 'ee/on_demand_scans/router';
import AllTab from 'ee/on_demand_scans/components/tabs/all.vue';
import RunningTab from 'ee/on_demand_scans/components/tabs/running.vue';
import FinishedTab from 'ee/on_demand_scans/components/tabs/finished.vue';
import ScheduledTab from 'ee/on_demand_scans/components/tabs/scheduled.vue';
import EmptyState from 'ee/on_demand_scans/components/empty_state.vue';

describe('OnDemandScans', () => {
  let wrapper;
  let router;

  // Finders
  const findTabs = () => wrapper.findComponent(GlTabs);
  const findAllTab = () => wrapper.findComponent(AllTab);
  const findRunningTab = () => wrapper.findComponent(RunningTab);
  const findFinishedTab = () => wrapper.findComponent(FinishedTab);
  const findScheduledTab = () => wrapper.findComponent(ScheduledTab);
  const findEmptyState = () => wrapper.findComponent(EmptyState);

  const createComponent = () => {
    wrapper = shallowMount(OnDemandScans, {
      router,
    });
  };

  beforeEach(() => {
    router = createRouter();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders an empty state when there is no data', () => {
    createComponent();

    expect(findEmptyState().exists()).toBe(true);
  });

  describe('when there is data', () => {
    beforeEach(() => {
      createComponent();
      wrapper.setData({ hasData: true });
    });

    it('renders the tabs if there is data', async () => {
      expect(findAllTab().exists()).toBe(true);
      expect(findRunningTab().exists()).toBe(true);
      expect(findFinishedTab().exists()).toBe(true);
      expect(findScheduledTab().exists()).toBe(true);
    });

    it('updates the route when the active tab changes', async () => {
      const finishedTabIndex = 2;
      findTabs().vm.$emit('input', finishedTabIndex);
      await wrapper.vm.$nextTick();

      expect(router.currentRoute.path).toBe('/finished');
    });
  });
});
