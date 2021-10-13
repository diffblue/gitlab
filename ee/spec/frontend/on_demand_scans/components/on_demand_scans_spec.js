import { GlTabs, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import OnDemandScans from 'ee/on_demand_scans/components/on_demand_scans.vue';
import ConfigurationPageLayout from 'ee/security_configuration/components/configuration_page_layout.vue';
import { createRouter } from 'ee/on_demand_scans/router';
import AllTab from 'ee/on_demand_scans/components/tabs/all.vue';
import RunningTab from 'ee/on_demand_scans/components/tabs/running.vue';
import FinishedTab from 'ee/on_demand_scans/components/tabs/finished.vue';
import ScheduledTab from 'ee/on_demand_scans/components/tabs/scheduled.vue';
import EmptyState from 'ee/on_demand_scans/components/empty_state.vue';

describe('OnDemandScans', () => {
  let wrapper;
  let router;

  // Props
  const newDastScanPath = '/on_demand_scans/new';

  // Finders
  const findNewScanLink = () => wrapper.findByTestId('new-scan-link');
  const findHelpPageLink = () => wrapper.findByTestId('help-page-link');
  const findTabs = () => wrapper.findComponent(GlTabs);
  const findAllTab = () => wrapper.findComponent(AllTab);
  const findRunningTab = () => wrapper.findComponent(RunningTab);
  const findFinishedTab = () => wrapper.findComponent(FinishedTab);
  const findScheduledTab = () => wrapper.findComponent(ScheduledTab);
  const findEmptyState = () => wrapper.findComponent(EmptyState);

  const createComponent = () => {
    wrapper = shallowMountExtended(OnDemandScans, {
      router,
      provide: {
        newDastScanPath,
      },
      stubs: {
        ConfigurationPageLayout,
        GlSprintf,
      },
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

    it('renders a link to the docs', () => {
      const link = findHelpPageLink();

      expect(link.exists()).toBe(true);
      expect(link.attributes('href')).toBe(
        '/help/user/application_security/dast/index#on-demand-scans',
      );
    });

    it('renders a link to create a new scan', () => {
      const link = findNewScanLink();

      expect(link.exists()).toBe(true);
      expect(link.attributes('href')).toBe(newDastScanPath);
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
