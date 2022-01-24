import { GlAlert, GlIntersectionObserver, GlLoadingIcon } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import { Portal } from 'portal-vue';
import VueApollo from 'vue-apollo';
import { nextTick } from 'vue';
import ProjectVulnerabilities from 'ee/security_dashboard/components/project/project_vulnerabilities.vue';
import SecurityScannerAlert from 'ee/security_dashboard/components/project/security_scanner_alert.vue';
import VulnerabilityList from 'ee/security_dashboard/components/shared/vulnerability_list.vue';
import securityScannersQuery from 'ee/security_dashboard/graphql/queries/project_security_scanners.query.graphql';
import vulnerabilitiesQuery from 'ee/security_dashboard/graphql/queries/project_vulnerabilities.query.graphql';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import { SCANNER_NAMES_MAP } from '~/security_configuration/components/constants';
import { generateVulnerabilities } from '../mock_data';

const localVue = createLocalVue();
localVue.use(VueApollo);

describe('Vulnerabilities app component', () => {
  useLocalStorageSpy();

  let wrapper;
  const apolloMock = {
    queries: { vulnerabilities: { loading: true } },
  };

  const createWrapper = ({ props = {}, $apollo = apolloMock } = {}, options = {}) => {
    wrapper = shallowMount(ProjectVulnerabilities, {
      provide: {
        projectFullPath: '#',
        hasJiraVulnerabilitiesIntegrationEnabled: false,
      },
      propsData: {
        dashboardDocumentation: '#',
        emptyStateSvgPath: '#',
        ...props,
      },
      mocks: {
        $apollo,
        fetchNextPage: () => {},
      },
      ...options,
    });
  };

  const securityScannersHandler = async ({
    available = [],
    enabled = [],
    pipelineRun = [],
  } = {}) => ({
    data: {
      project: {
        id: 'project-1',
        securityScanners: { available, enabled, pipelineRun },
      },
    },
  });

  const findIntersectionObserver = () => wrapper.findComponent(GlIntersectionObserver);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findSecurityScannerAlert = (root = wrapper) => root.findComponent(SecurityScannerAlert);
  const findVulnerabilityList = () => wrapper.findComponent(VulnerabilityList);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

  const expectLoadingState = ({ initial = false, nextPage = false }) => {
    expect(findVulnerabilityList().props('isLoading')).toBe(initial);
    expect(findLoadingIcon().exists()).toBe(nextPage);
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('when the vulnerabilities are loading', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('should show the initial loading state', () => {
      expectLoadingState({ initial: true });
    });
  });

  describe('with some vulnerabilities', () => {
    let vulnerabilities;

    beforeEach(() => {
      createWrapper();

      vulnerabilities = generateVulnerabilities();
      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({ vulnerabilities });
    });

    it('should not show any loading state', () => {
      expectLoadingState({ initial: false, nextPage: false });
    });

    it('should pass the vulnerabilities to the vulnerabilities list', () => {
      expect(findVulnerabilityList().props().vulnerabilities).toEqual(vulnerabilities);
    });

    it('should not render the observer component', () => {
      expect(findIntersectionObserver().exists()).toBe(false);
    });

    it('should not render the alert', () => {
      expect(findAlert().exists()).toBe(false);
    });

    it('defaults to severity column for sorting', () => {
      expect(wrapper.vm.sortBy).toBe('severity');
    });

    it('defaults to desc as sorting direction', () => {
      expect(wrapper.vm.sortDirection).toBe('desc');
    });

    it('handles sorting', () => {
      findVulnerabilityList().vm.$emit('sort-changed', {
        sortBy: 'description',
        sortDesc: false,
      });

      expect(wrapper.vm.sortBy).toBe('description');
      expect(wrapper.vm.sortDirection).toBe('asc');
    });
  });

  describe('with more than a page of vulnerabilities', () => {
    let vulnerabilities;

    beforeEach(() => {
      createWrapper();

      vulnerabilities = generateVulnerabilities();
      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({
        vulnerabilities,
        pageInfo: {
          hasNextPage: true,
        },
      });
    });

    it('should render the observer component', () => {
      expect(findIntersectionObserver().exists()).toBe(true);
    });

    it('should render the next page loading spinner', () => {
      expectLoadingState({ nextPage: true });
    });
  });

  describe(`when there's an error loading vulnerabilities`, () => {
    beforeEach(() => {
      createWrapper();
      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({ errorLoadingVulnerabilities: true });
    });

    it('should render the alert', () => {
      expect(findAlert().exists()).toBe(true);
    });
  });

  describe('when filter or sort is changed', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('should show the initial loading state when the filter is changed', () => {
      wrapper.setProps({ filter: {} });

      expectLoadingState({ initial: true });
    });

    it('should show the initial loading state when the sort is changed', () => {
      findVulnerabilityList().vm.$emit('sort-changed', {
        sortBy: 'description',
        sortDesc: false,
      });

      expectLoadingState({ initial: true });
    });
  });

  describe('filters prop', () => {
    const vulnerabilitiesHandler = jest.fn().mockResolvedValue({
      data: {
        project: {
          vulnerabilities: {
            nodes: [],
            pageInfo: { startCursor: '', endCursor: '' },
          },
        },
      },
    });

    const createWrapperWithApollo = ({ filters }) => {
      wrapper = shallowMount(ProjectVulnerabilities, {
        localVue,
        apolloProvider: createMockApollo([
          [vulnerabilitiesQuery, vulnerabilitiesHandler],
          [securityScannersQuery, securityScannersHandler],
        ]),
        propsData: { filters },
        provide: { groupFullPath: 'path' },
      });
    };

    it('does not run the query when filters is null', () => {
      createWrapperWithApollo({ filters: null });

      expect(vulnerabilitiesHandler).not.toHaveBeenCalled();
    });

    it('runs query when filters is an object', () => {
      createWrapperWithApollo({ filters: {} });

      expect(vulnerabilitiesHandler).toHaveBeenCalled();
    });
  });

  describe('security scanner alerts', () => {
    const vulnerabilityReportAlertsPortal = 'test-alerts-portal';

    const createWrapperForScannerAlerts = async ({ securityScanners }) => {
      wrapper = shallowMount(ProjectVulnerabilities, {
        localVue,
        apolloProvider: createMockApollo([
          [securityScannersQuery, () => securityScannersHandler(securityScanners)],
        ]),
        provide: {
          vulnerabilityReportAlertsPortal,
          projectFullPath: 'path',
        },
        stubs: {
          LocalStorageSync,
        },
      });

      await waitForPromises();
    };

    describe.each`
      available   | enabled     | pipelineRun | expectAlertShown
      ${['DAST']} | ${[]}       | ${[]}       | ${true}
      ${['DAST']} | ${['DAST']} | ${[]}       | ${true}
      ${['DAST']} | ${[]}       | ${['DAST']} | ${true}
      ${['DAST']} | ${['DAST']} | ${['DAST']} | ${false}
      ${[]}       | ${[]}       | ${[]}       | ${false}
    `('visibility', ({ available, enabled, pipelineRun, expectAlertShown }) => {
      beforeEach(() => {});

      it(`should${expectAlertShown ? '' : ' not'} show the alert`, async () => {
        await createWrapperForScannerAlerts({
          securityScanners: { available, enabled, pipelineRun },
        });

        expect(findSecurityScannerAlert().exists()).toBe(expectAlertShown);
      });

      if (expectAlertShown) {
        it('should portal the alert to the provided vulnerabilityReportAlertsPortal', async () => {
          await createWrapperForScannerAlerts({
            securityScanners: { available, enabled, pipelineRun },
          });

          const portal = wrapper.findComponent(Portal);
          expect(portal.props('to')).toBe(vulnerabilityReportAlertsPortal);

          expect(findSecurityScannerAlert(portal).exists()).toBe(true);
        });
      }

      it('should never show the alert once it has been dismissed', async () => {
        window.localStorage.setItem(
          ProjectVulnerabilities.SCANNER_ALERT_DISMISSED_LOCAL_STORAGE_KEY,
          'true',
        );

        await createWrapperForScannerAlerts({
          securityScanners: { available, enabled, pipelineRun },
        });

        expect(findSecurityScannerAlert().exists()).toBe(false);
      });
    });

    describe.each(Object.keys(SCANNER_NAMES_MAP))(
      'When %s is available but not enabled',
      (scanner) => {
        const translatedScannerName = SCANNER_NAMES_MAP[scanner];

        beforeEach(() => {
          createWrapperForScannerAlerts({
            securityScanners: { available: [scanner], enabled: [], pipelineRun: [] },
          });
        });

        it(`passes the translated scanner's name to the alert (${translatedScannerName})`, () => {
          expect(findSecurityScannerAlert().props('notEnabledScanners')[0]).toBe(
            translatedScannerName,
          );
        });
      },
    );

    describe('dismissal', () => {
      beforeEach(() => {
        return createWrapperForScannerAlerts({
          securityScanners: { available: ['DAST'], enabled: [], pipelineRun: [] },
        });
      });

      it('should hide the alert when it is dismissed', async () => {
        const scannerAlert = findSecurityScannerAlert();
        expect(scannerAlert.exists()).toBe(true);

        scannerAlert.vm.$emit('dismiss');

        await nextTick();

        expect(scannerAlert.exists()).toBe(false);
      });

      it('should remember the dismissal state', async () => {
        findSecurityScannerAlert().vm.$emit('dismiss');

        await nextTick();

        expect(window.localStorage.setItem.mock.calls).toContainEqual([
          ProjectVulnerabilities.SCANNER_ALERT_DISMISSED_LOCAL_STORAGE_KEY,
          'true',
        ]);
      });
    });
  });
});
