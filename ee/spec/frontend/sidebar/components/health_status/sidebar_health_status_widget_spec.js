import * as Sentry from '@sentry/browser';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { createAlert } from '~/alert';
import SidebarEditableItem from '~/sidebar/components/sidebar_editable_item.vue';
import IssueHealthStatus from 'ee/related_items_tree/components/issue_health_status.vue';
import HealthStatusDropdown from 'ee/sidebar/components/health_status/health_status_dropdown.vue';
import SidebarHealthStatusWidget from 'ee/sidebar/components/health_status/sidebar_health_status_widget.vue';
import {
  healthStatusQueries,
  healthStatusTextMap,
  HEALTH_STATUS_ON_TRACK,
  HEALTH_STATUS_NEEDS_ATTENTION,
  HEALTH_STATUS_AT_RISK,
} from 'ee/sidebar/constants';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mockTracking } from 'helpers/tracking_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { getHealthStatusMutationResponse, getHealthStatusQueryResponse } from '../../mock_data';

jest.mock('@sentry/browser');
jest.mock('~/alert');

describe('SidebarHealthStatusWidget component', () => {
  let wrapper;

  Vue.use(VueApollo);

  const findHealthStatusDropdown = () => wrapper.findComponent(HealthStatusDropdown);
  const findIssueHealthStatus = () => wrapper.findComponent(IssueHealthStatus);

  const createQueryHandler = ({ state, healthStatus }) =>
    jest.fn().mockResolvedValue(getHealthStatusQueryResponse({ state, healthStatus }));
  const createMutationHandler = ({ healthStatus }) =>
    jest.fn().mockResolvedValue(getHealthStatusMutationResponse({ healthStatus }));

  const mountComponent = ({
    healthStatus = HEALTH_STATUS_ON_TRACK,
    issuableType = 'issue',
    state = 'opened',
    mutationHandler = createMutationHandler({ healthStatus }),
  } = {}) => {
    wrapper = shallowMount(SidebarHealthStatusWidget, {
      apolloProvider: createMockApollo([
        [healthStatusQueries[issuableType].query, createQueryHandler({ healthStatus, state })],
        [healthStatusQueries[issuableType].mutation, mutationHandler],
      ]),
      provide: {
        canUpdate: true,
      },
      propsData: {
        fullPath: 'foo/bar',
        iid: '1',
        issuableType,
      },
    });
  };

  it.each`
    healthStatus                     | healthStatusText
    ${HEALTH_STATUS_ON_TRACK}        | ${healthStatusTextMap[HEALTH_STATUS_ON_TRACK]}
    ${HEALTH_STATUS_NEEDS_ATTENTION} | ${healthStatusTextMap[HEALTH_STATUS_NEEDS_ATTENTION]}
    ${HEALTH_STATUS_AT_RISK}         | ${healthStatusTextMap[HEALTH_STATUS_AT_RISK]}
  `(
    'renders "$healthStatusText" when health status = "$healthStatus"',
    async ({ healthStatus, healthStatusText }) => {
      mountComponent({ healthStatus });
      await waitForPromises();

      expect(wrapper.findComponent(SidebarEditableItem).text()).toContain(healthStatusText);
      expect(findIssueHealthStatus().exists()).toBe(true);
      expect(findIssueHealthStatus().props('healthStatus')).toBe(healthStatus);
    },
  );

  it('renders dropdown', async () => {
    mountComponent();
    await waitForPromises();

    expect(findHealthStatusDropdown().props()).toEqual({ healthStatus: HEALTH_STATUS_ON_TRACK });
  });

  describe('when dropdown value is selected', () => {
    it('calls a GraphQL mutation to update the health status', async () => {
      const healthStatus = HEALTH_STATUS_AT_RISK;
      const mutationHandler = createMutationHandler({ healthStatus });
      mountComponent({ healthStatus: HEALTH_STATUS_ON_TRACK, mutationHandler });
      wrapper.vm.$refs.editable.collapse = jest.fn();

      findHealthStatusDropdown().vm.$emit('change', healthStatus);
      await waitForPromises();

      expect(mutationHandler).toHaveBeenCalledWith({
        healthStatus,
        iid: '1',
        projectPath: 'foo/bar',
      });
      expect(wrapper.emitted('statusUpdated')).toEqual([[healthStatus]]);
    });

    it('does not call a GraphQL mutation when the health status value is the same', async () => {
      const healthStatus = HEALTH_STATUS_AT_RISK;
      const mutationHandler = createMutationHandler({ healthStatus });
      mountComponent({ healthStatus, mutationHandler });
      wrapper.vm.$refs.editable.collapse = jest.fn();
      await waitForPromises();

      findHealthStatusDropdown().vm.$emit('change', healthStatus);

      expect(mutationHandler).not.toHaveBeenCalled();
      expect(wrapper.emitted('statusUpdated')).not.toBeTruthy();
    });

    it('shows an alert message when there is an error', async () => {
      const error = new Error('oh no');
      mountComponent({ mutationHandler: jest.fn().mockRejectedValue(error) });
      wrapper.vm.$refs.editable.collapse = jest.fn();

      findHealthStatusDropdown().vm.$emit('change', HEALTH_STATUS_AT_RISK);
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'Something went wrong while setting issue health status.',
      });
      expect(Sentry.captureException).toHaveBeenCalledWith(error);
      expect(wrapper.emitted('statusUpdated')).not.toBeTruthy();
    });

    it('tracks updating health status', async () => {
      const healthStatus = HEALTH_STATUS_AT_RISK;
      const mutationHandler = createMutationHandler({ healthStatus });
      mountComponent({ mutationHandler });
      const trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
      wrapper.vm.$refs.editable.collapse = jest.fn();

      findHealthStatusDropdown().vm.$emit('change', healthStatus);
      await waitForPromises();

      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'change_health_status', {
        property: healthStatus,
      });
      expect(wrapper.emitted('statusUpdated')).toEqual([[healthStatus]]);
    });
  });
});
