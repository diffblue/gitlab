import { GlDropdownItem, GlFormGroup, GlDropdown, GlBadge } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount, mount } from '@vue/test-utils';
import WorkItemHealthStatus from 'ee/work_items/components/work_item_health_status.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mockTracking } from 'helpers/tracking_helper';
import waitForPromises from 'helpers/wait_for_promises';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';
import workItemHealthStatusSubscription from 'ee/work_items/graphql/work_item_health_status.subscription.graphql';
import { TRACKING_CATEGORY_SHOW } from '~/work_items/constants';
import {
  HEALTH_STATUS_AT_RISK,
  HEALTH_STATUS_I18N_NONE,
  HEALTH_STATUS_NEEDS_ATTENTION,
  HEALTH_STATUS_ON_TRACK,
  healthStatusTextMap,
} from 'ee/sidebar/constants';

import {
  updateWorkItemMutationResponse,
  workItemByIidResponseFactory,
  workItemHealthStatusSubscriptionResponse,
} from 'jest/work_items/mock_data';

describe('WorkItemHealthStatus component', () => {
  Vue.use(VueApollo);

  let wrapper;

  const healthStatusSubscriptionHandler = jest
    .fn()
    .mockResolvedValue(workItemHealthStatusSubscriptionResponse);

  const workItemId = 'gid://gitlab/WorkItem/1';
  const workItemType = 'Task';
  const workItemQueryResponse = workItemByIidResponseFactory({ canUpdate: true, canDelete: true });
  const workItemQueryHandler = jest.fn().mockResolvedValue(workItemQueryResponse);

  const findFormGroup = () => wrapper.findComponent(GlFormGroup);
  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findBadge = () => wrapper.findComponent(GlBadge);
  const findDropdownItemAt = (index) => wrapper.findAllComponents(GlDropdownItem).at(index);

  const createComponent = ({
    canUpdate = true,
    hasIssuableHealthStatusFeature = true,
    healthStatus,
    mutationHandler = jest.fn().mockResolvedValue(updateWorkItemMutationResponse),
    mountFn = shallowMount,
  } = {}) => {
    wrapper = mountFn(WorkItemHealthStatus, {
      apolloProvider: createMockApollo([
        [workItemByIidQuery, workItemQueryHandler],
        [updateWorkItemMutation, mutationHandler],
        [workItemHealthStatusSubscription, healthStatusSubscriptionHandler],
      ]),
      propsData: {
        canUpdate,
        healthStatus,
        workItemId,
        workItemIid: '1',
        workItemType,
      },
      provide: {
        fullPath: 'test-project-path',
        hasIssuableHealthStatusFeature,
      },
    });
  };

  describe('`hasIssuableHealthStatusFeature` licensed feature', () => {
    describe.each`
      description             | hasIssuableHealthStatusFeature | exists
      ${'when available'}     | ${true}                        | ${true}
      ${'when not available'} | ${false}                       | ${false}
    `('$description', ({ hasIssuableHealthStatusFeature, exists }) => {
      it(`${hasIssuableHealthStatusFeature ? 'renders' : 'does not render'} component`, () => {
        createComponent({ hasIssuableHealthStatusFeature });

        expect(findFormGroup().exists()).toBe(exists);
      });
    });
  });

  describe('update permissions', () => {
    describe.each`
      description                     | canUpdate | exists
      ${'when allowed to update'}     | ${true}   | ${true}
      ${'when not allowed to update'} | ${false}  | ${false}
    `('$description', ({ canUpdate, exists }) => {
      it(`${canUpdate ? 'renders' : 'does not render'} the dropdown`, () => {
        createComponent({ canUpdate });

        expect(findDropdown().exists()).toBe(exists);
      });
    });
  });

  describe('health status rendering', () => {
    describe('correct text', () => {
      it.each`
        healthStatus                     | text
        ${HEALTH_STATUS_ON_TRACK}        | ${healthStatusTextMap[HEALTH_STATUS_ON_TRACK]}
        ${HEALTH_STATUS_NEEDS_ATTENTION} | ${healthStatusTextMap[HEALTH_STATUS_NEEDS_ATTENTION]}
        ${HEALTH_STATUS_AT_RISK}         | ${healthStatusTextMap[HEALTH_STATUS_AT_RISK]}
        ${null}                          | ${HEALTH_STATUS_I18N_NONE}
      `('renders "$text" when health status = "$healthStatus"', ({ healthStatus, text }) => {
        createComponent({ healthStatus, mountFn: mount });

        expect(wrapper.text()).toContain(text);
      });
    });

    describe('badge renders correct variant', () => {
      it.each`
        healthStatus                     | variant
        ${HEALTH_STATUS_ON_TRACK}        | ${'success'}
        ${HEALTH_STATUS_NEEDS_ATTENTION} | ${'warning'}
        ${HEALTH_STATUS_AT_RISK}         | ${'danger'}
      `('uses "$variant" when health status = "$healthStatus"', ({ healthStatus, variant }) => {
        createComponent({ healthStatus, mountFn: mount });

        expect(findBadge().props('variant')).toBe(variant);
      });
    });
  });

  describe('health status input', () => {
    it.each`
      index | expectedStatus
      ${0}  | ${null}
      ${1}  | ${'onTrack'}
      ${2}  | ${'needsAttention'}
      ${3}  | ${'atRisk'}
    `('calls mutation with health status = "$expectedStatus"', ({ index, expectedStatus }) => {
      const mutationSpy = jest.fn().mockResolvedValue(updateWorkItemMutationResponse);
      createComponent({
        mutationHandler: mutationSpy,
      });

      findDropdownItemAt(index).vm.$emit('click');

      expect(mutationSpy).toHaveBeenCalledWith({
        input: {
          id: workItemId,
          healthStatusWidget: {
            healthStatus: expectedStatus,
          },
        },
      });
    });

    it('emits an error when there is a GraphQL error', async () => {
      const response = {
        data: {
          workItemUpdate: {
            errors: ['Error!'],
            workItem: {},
          },
        },
      };
      createComponent({
        mutationHandler: jest.fn().mockResolvedValue(response),
      });

      findDropdownItemAt(1).vm.$emit('click');
      await waitForPromises();

      expect(wrapper.emitted('error')).toEqual([
        ['Something went wrong while updating the task. Please try again.'],
      ]);
    });

    it('emits an error when there is a network error', async () => {
      createComponent({
        mutationHandler: jest.fn().mockRejectedValue(new Error()),
      });

      findDropdownItemAt(1).vm.$emit('click');
      await waitForPromises();

      expect(wrapper.emitted('error')).toEqual([
        ['Something went wrong while updating the task. Please try again.'],
      ]);
    });

    it('tracks updating the health status', () => {
      const trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
      createComponent();

      findDropdownItemAt(1).vm.$emit('click');

      expect(trackingSpy).toHaveBeenCalledWith(TRACKING_CATEGORY_SHOW, 'updated_health_status', {
        category: TRACKING_CATEGORY_SHOW,
        label: 'item_health_status',
        property: 'type_Task',
      });
    });
  });
});
