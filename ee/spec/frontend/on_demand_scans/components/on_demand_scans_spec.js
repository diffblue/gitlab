import { GlSprintf, GlTabs } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { merge } from 'lodash';
import onDemandScansCountsMock from 'test_fixtures/graphql/on_demand_scans/graphql/on_demand_scan_counts.query.graphql.json';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import OnDemandScans from 'ee/on_demand_scans/components/on_demand_scans.vue';
import { PIPELINE_TABS_KEYS } from 'ee/on_demand_scans/constants';
import ConfigurationPageLayout from 'ee/security_configuration/components/configuration_page_layout.vue';
import { createRouter } from 'ee/on_demand_scans/router';
import AllTab from 'ee/on_demand_scans/components/tabs/all.vue';
import RunningTab from 'ee/on_demand_scans/components/tabs/running.vue';
import FinishedTab from 'ee/on_demand_scans/components/tabs/finished.vue';
import ScheduledTab from 'ee/on_demand_scans/components/tabs/scheduled.vue';
import SavedTab from 'ee/on_demand_scans/components/tabs/saved.vue';
import EmptyState from 'ee/on_demand_scans/components/empty_state.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import onDemandScansCounts from 'ee/on_demand_scans/graphql/on_demand_scan_counts.query.graphql';
import waitForPromises from 'helpers/wait_for_promises';

Vue.use(VueApollo);

describe('OnDemandScans', () => {
  let wrapper;
  let router;
  let requestHandler;

  // Props
  const newDastScanPath = '/on_demand_scans/new';
  const projectPath = '/namespace/project';
  const projectOnDemandScanCountsEtag = `/api/graphql:on_demand_scan/counts/${projectPath}`;
  const nonEmptyInitialPipelineCounts = {
    all: 12,
    running: 3,
    finished: 9,
    scheduled: 5,
    saved: 3,
  };
  const emptyInitialPipelineCounts = Object.fromEntries(PIPELINE_TABS_KEYS.map((key) => [key, 0]));

  // Finders
  const findNewScanLink = () => wrapper.findByTestId('new-scan-link');
  const findHelpPageLink = () => wrapper.findByTestId('help-page-link');
  const findTabs = () => wrapper.findByTestId('on-demand-scans-tabs');
  const findAuditorActionsAlert = () => wrapper.findByTestId('on-demand-scan-auditor-message');
  const findAllTab = () => wrapper.findComponent(AllTab);
  const findRunningTab = () => wrapper.findComponent(RunningTab);
  const findFinishedTab = () => wrapper.findComponent(FinishedTab);
  const findScheduledTab = () => wrapper.findComponent(ScheduledTab);
  const findSavedTab = () => wrapper.findComponent(SavedTab);
  const findEmptyState = () => wrapper.findComponent(EmptyState);

  // Helpers
  const createMockApolloProvider = () => {
    return createMockApollo([[onDemandScansCounts, requestHandler]]);
  };

  // Assertions
  const expectTabsToBeRendered = () => {
    expect(findAllTab().exists()).toBe(true);
    expect(findRunningTab().exists()).toBe(true);
    expect(findFinishedTab().exists()).toBe(true);
    expect(findScheduledTab().exists()).toBe(true);
    expect(findSavedTab().exists()).toBe(true);
  };

  const createComponent = (options = {}, canEditOnDemandScans = true) => {
    wrapper = shallowMountExtended(
      OnDemandScans,
      merge(
        {
          apolloProvider: createMockApolloProvider(),
          router,
          provide: {
            canEditOnDemandScans,
            newDastScanPath,
            projectPath,
            projectOnDemandScanCountsEtag,
          },
          stubs: {
            ConfigurationPageLayout,
            GlSprintf,
            GlScrollableTabs: GlTabs,
          },
        },
        {
          propsData: {
            initialOnDemandScanCounts: nonEmptyInitialPipelineCounts,
          },
        },
        options,
      ),
    );
  };

  beforeEach(() => {
    requestHandler = jest.fn().mockResolvedValue(onDemandScansCountsMock);
    router = createRouter();
  });

  it('renders an empty state when there is no data', () => {
    createComponent({
      propsData: {
        initialOnDemandScanCounts: emptyInitialPipelineCounts,
      },
    });

    expect(findEmptyState().exists()).toBe(true);
  });

  it('updates on-demand scans counts and shows the tabs once there is some data', async () => {
    createComponent({
      propsData: {
        initialOnDemandScanCounts: emptyInitialPipelineCounts,
      },
    });

    expect(findTabs().exists()).toBe(false);
    expect(findEmptyState().exists()).toBe(true);
    expect(requestHandler).toHaveBeenCalled();

    await waitForPromises();

    expect(findTabs().exists()).toBe(true);
    expect(findEmptyState().exists()).toBe(false);
  });

  describe('non-empty states', () => {
    it.each`
      description    | counts
      ${'scheduled'} | ${{ scheduled: 0 }}
      ${'saved'}     | ${{ saved: 0 }}
    `(
      'shows the tabs when there are no pipelines but there are $description scans',
      ({ counts }) => {
        createComponent({
          propsData: {
            initialOnDemandScanCounts: {
              all: 0,
              ...counts,
            },
          },
        });

        expectTabsToBeRendered();
      },
    );
  });

  describe('when there is data', () => {
    beforeEach(() => {
      createComponent();
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
      expectTabsToBeRendered();
    });

    it('sets the initial route to /all', () => {
      expect(findTabs().props('value')).toBe(0);
      expect(router.currentRoute.path).toBe('/all');
    });
  });

  describe('user with auditor role', () => {
    it.each`
      canEditOnDemandScans | infoMessageVisible
      ${false}             | ${true}
      ${true}              | ${false}
    `(
      'should hide action buttons for auditor user',
      ({ canEditOnDemandScans, infoMessageVisible }) => {
        createComponent({}, canEditOnDemandScans);

        expect(findAuditorActionsAlert().exists()).toBe(infoMessageVisible);
      },
    );
  });
});
