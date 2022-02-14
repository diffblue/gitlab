import { GlAlert, GlDrawer, GlSkeletonLoader } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { createLocalVue } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import { nextTick } from 'vue';
import AlertDrawer from 'ee/threat_monitoring/components/alerts/alert_drawer.vue';
import { DRAWER_ERRORS } from 'ee/threat_monitoring/components/alerts/constants';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import getAlertDetailsQuery from '~/graphql_shared/queries/alert_details.query.graphql';
import { visitUrl } from '~/lib/utils/url_utility';
import SidebarAssigneesWidget from '~/sidebar/components/assignees/sidebar_assignees_widget.vue';
import SidebarStatus from '~/vue_shared/alert_details/components/sidebar/sidebar_status.vue';
import {
  erroredGetAlertDetailsQuerySpy,
  getAlertDetailsQueryErrorMessage,
  getAlertDetailsQuerySpy,
} from '../../mocks/mock_apollo';
import { mockAlertDetails, mockAlerts } from '../../mocks/mock_data';

jest.mock('~/lib/utils/url_utility', () => ({
  visitUrl: jest.fn(),
  joinPaths: jest.requireActual('~/lib/utils/url_utility').joinPaths,
}));

let localVue;

describe('Alert Drawer', () => {
  let wrapper;
  const DEFAULT_PROJECT_PATH = '#';

  const mutateSpy = jest.fn().mockResolvedValue({
    data: { createAlertIssue: { errors: [], issue: { webUrl: '/#/-/issues/03' } } },
  });
  let querySpy;

  const createMockApolloProvider = (query) => {
    localVue.use(VueApollo);
    return createMockApollo([[getAlertDetailsQuery, query]]);
  };

  const shallowApolloMock = ({ loading = false, mutate = mutateSpy }) => ({
    mutate,
    queries: { alertDetails: { loading } },
  });

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findAssignee = () => wrapper.findComponent(SidebarAssigneesWidget);
  const findCreateIssueButton = () => wrapper.findByTestId('create-issue-button');
  const findDrawer = () => wrapper.findComponent(GlDrawer);
  const findIssueLink = () => wrapper.findByTestId('issue-link');
  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findDetails = () => wrapper.findByTestId('details-list');
  const findStatus = () => wrapper.findComponent(SidebarStatus);

  const createWrapper = ({
    $apollo,
    apolloSpy = getAlertDetailsQuerySpy,
    mount = shallowMountExtended,
    props = {},
  } = {}) => {
    let apolloOptions;
    if ($apollo) {
      apolloOptions = {
        mocks: {
          $apollo,
        },
      };
    } else {
      localVue = createLocalVue();
      querySpy = apolloSpy;
      const mockApollo = createMockApolloProvider(querySpy);
      apolloOptions = {
        localVue,
        apolloProvider: mockApollo,
      };
    }

    wrapper = mount(AlertDrawer, {
      propsData: {
        isAlertDrawerOpen: true,
        projectId: '1',
        selectedAlert: mockAlertDetails,
        ...props,
      },
      provide: {
        projectPath: DEFAULT_PROJECT_PATH,
      },
      stubs: { GlDrawer, SidebarAssigneesWidget: true, SidebarStatus: true },
      ...apolloOptions,
    });
  };

  describe('default', () => {
    it.each`
      component                  | status                | findComponent            | state    | mount
      ${'alert'}                 | ${'does not display'} | ${findAlert}             | ${false} | ${undefined}
      ${'"Create Issue" button'} | ${'does not display'} | ${findCreateIssueButton} | ${false} | ${undefined}
      ${'assignee widget'}       | ${'does display'}     | ${findAssignee}          | ${true}  | ${undefined}
      ${'status widget'}         | ${'does display'}     | ${findStatus}            | ${true}  | ${undefined}
      ${'details list'}          | ${'does display'}     | ${findDetails}           | ${true}  | ${undefined}
      ${'drawer'}                | ${'does display'}     | ${findDrawer}            | ${true}  | ${undefined}
      ${'issue link'}            | ${'does display'}     | ${findIssueLink}         | ${true}  | ${undefined}
      ${'skeleton loader'}       | ${'does not display'} | ${findSkeletonLoader}    | ${false} | ${mountExtended}
    `('$status the $component', async ({ findComponent, state, mount }) => {
      createWrapper({ $apollo: shallowApolloMock({}), mount });
      await nextTick();
      expect(findComponent().exists()).toBe(state);
    });
  });

  it('displays the issue link if an alert already has an issue associated with it', () => {
    createWrapper();
    expect(findIssueLink().exists()).toBe(true);
    expect(findIssueLink().attributes('href')).toBe('http://test.com/05');
  });

  it('displays the loading icon when retrieving the alert details', () => {
    createWrapper({ $apollo: shallowApolloMock({ loading: true }) });
    expect(findSkeletonLoader().exists()).toBe(true);
    expect(findDetails().exists()).toBe(false);
  });

  it('displays the alert when there was an error retrieving alert details', async () => {
    const captureExceptionSpy = jest.spyOn(Sentry, 'captureException');
    createWrapper({ apolloSpy: erroredGetAlertDetailsQuerySpy });
    await waitForPromises();
    expect(findAlert().exists()).toBe(true);
    expect(findAlert().text()).toBe(DRAWER_ERRORS.DETAILS);
    expect(captureExceptionSpy).toHaveBeenCalled();
    expect(captureExceptionSpy.mock.calls[0][0].message).toBe(getAlertDetailsQueryErrorMessage);
  });

  describe('creating an issue', () => {
    it('navigates to the created issue when the "Create Issue" button is clicked', async () => {
      const captureExceptionSpy = jest.spyOn(Sentry, 'captureException');
      createWrapper({ $apollo: shallowApolloMock({}), props: { selectedAlert: mockAlerts[2] } });
      expect(findCreateIssueButton().exists()).toBe(true);
      findCreateIssueButton().vm.$emit('click');
      await waitForPromises();
      expect(mutateSpy).toHaveBeenCalledTimes(1);
      expect(captureExceptionSpy).not.toHaveBeenCalled();
      expect(visitUrl).toHaveBeenCalledWith('/#/-/issues/03');
    });

    it('displays the alert when there was an error creating an issue', async () => {
      const errorMessage = 'GraphQL error';
      const captureExceptionSpy = jest.spyOn(Sentry, 'captureException');
      const erroredMutateSpy = jest
        .fn()
        .mockResolvedValue({ data: { createAlertIssue: { errors: [errorMessage] } } });

      createWrapper({
        $apollo: shallowApolloMock({ mutate: erroredMutateSpy }),
        props: { selectedAlert: mockAlerts[2] },
      });
      expect(findCreateIssueButton().exists()).toBe(true);
      findCreateIssueButton().vm.$emit('click');
      await waitForPromises();
      expect(erroredMutateSpy).toHaveBeenCalledTimes(1);
      expect(visitUrl).not.toHaveBeenCalled();
      expect(findAlert().exists()).toBe(true);
      expect(findAlert().text()).toBe(DRAWER_ERRORS.CREATE_ISSUE);
      expect(captureExceptionSpy).toHaveBeenCalledTimes(1);
      expect(captureExceptionSpy.mock.calls[0][0].message).toBe(errorMessage);
    });
  });

  it('handles an alert assignee update', () => {
    createWrapper({ props: { selectedAlert: mockAlerts[0] } });
    expect(wrapper.emitted('alert-update')).toBeUndefined();
    findAssignee().vm.$emit('assignees-updated');
    expect(wrapper.emitted('alert-update')).toEqual([[]]);
  });

  it('handles an alert status update', () => {
    createWrapper({ props: { selectedAlert: mockAlerts[0] } });
    expect(wrapper.emitted('alert-update')).toBeUndefined();
    findStatus().vm.$emit('alert-update');
    expect(wrapper.emitted('alert-update')).toEqual([[]]);
  });
});
