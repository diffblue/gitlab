import { GlSprintf, GlTabs } from '@gitlab/ui';
import { merge } from 'lodash';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import OnDemandScans from 'ee/on_demand_scans/components/on_demand_scans.vue';
import ConfigurationPageLayout from 'ee/security_configuration/components/configuration_page_layout.vue';
import { createRouter } from 'ee/on_demand_scans/router';
import AllTab from 'ee/on_demand_scans/components/tabs/all.vue';
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
  const findEmptyState = () => wrapper.findComponent(EmptyState);

  const createComponent = (options = {}) => {
    wrapper = shallowMountExtended(
      OnDemandScans,
      merge(
        {
          router,
          provide: {
            newDastScanPath,
          },
          stubs: {
            ConfigurationPageLayout,
            GlSprintf,
            GlTabs,
          },
        },
        options,
      ),
    );
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
      createComponent({
        propsData: {
          pipelinesCount: 12,
        },
      });
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

    it('renders the tabs', () => {
      expect(findAllTab().exists()).toBe(true);
    });

    it('sets the initial route to /all', () => {
      expect(findTabs().props('value')).toBe(0);
      expect(router.currentRoute.path).toBe('/all');
    });
  });
});
