import { GlForm, GlFormInput } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import WorkItemProgress from 'ee/work_items/components/work_item_progress.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mockTracking } from 'helpers/tracking_helper';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { __ } from '~/locale';
import { TRACKING_CATEGORY_SHOW } from '~/work_items/constants';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import workItemQuery from '~/work_items/graphql/work_item.query.graphql';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';
import {
  updateWorkItemMutationResponse,
  workItemResponseFactory,
  projectWorkItemResponse,
} from 'jest/work_items/mock_data';

describe('WorkItemProgress component', () => {
  Vue.use(VueApollo);

  let wrapper;

  const workItemId = 'gid://gitlab/WorkItem/1';
  const workItemType = 'Objective';
  const workItemQueryResponse = workItemResponseFactory({ canUpdate: true, canDelete: true });
  const workItemQueryHandler = jest.fn().mockResolvedValue(workItemQueryResponse);
  const workItemByIidResponseHandler = jest.fn().mockResolvedValue(projectWorkItemResponse);

  const findForm = () => wrapper.findComponent(GlForm);
  const findInput = () => wrapper.findComponent(GlFormInput);

  const createComponent = ({
    canUpdate = false,
    hasOkrsFeature = true,
    okrsMvc = true,
    isEditing = false,
    progress,
    mutationHandler = jest.fn().mockResolvedValue(updateWorkItemMutationResponse),
    fetchByIid = false,
    queryVariables = { id: workItemId },
  } = {}) => {
    wrapper = mountExtended(WorkItemProgress, {
      apolloProvider: createMockApollo([
        [workItemQuery, workItemQueryHandler],
        [updateWorkItemMutation, mutationHandler],
        [workItemByIidQuery, workItemByIidResponseHandler],
      ]),
      propsData: {
        canUpdate,
        progress,
        workItemId,
        workItemType,
        fetchByIid,
        queryVariables,
      },
      provide: {
        hasOkrsFeature,
        glFeatures: {
          okrsMvc,
        },
      },
    });

    if (isEditing) {
      findInput().vm.$emit('focus');
    }
  };

  describe('`okrs` licensed feature and `okrsMvc', () => {
    describe.each`
      description               | hasOkrsFeature | okrsMvc  | exists
      ${'when both enabled'}    | ${true}        | ${true}  | ${true}
      ${'when one is disabled'} | ${false}       | ${true}  | ${false}
      ${'when one is disabled'} | ${true}        | ${false} | ${false}
      ${'when both disabled'}   | ${false}       | ${false} | ${false}
    `('$description', ({ hasOkrsFeature, okrsMvc, exists }) => {
      it(`${hasOkrsFeature && okrsMvc ? 'renders' : 'does not render'} component`, () => {
        createComponent({ hasOkrsFeature, okrsMvc });

        expect(findForm().exists()).toBe(exists);
      });
    });
  });

  describe('progress input', () => {
    it('has "Progress" label', () => {
      createComponent();

      expect(wrapper.findByLabelText(__('Progress')).exists()).toBe(true);
    });

    describe('placeholder attribute', () => {
      describe.each`
        description                             | isEditing | canUpdate | value
        ${'when not editing and cannot update'} | ${false}  | ${false}  | ${__('None')}
        ${'when editing and cannot update'}     | ${true}   | ${false}  | ${__('None')}
        ${'when not editing and can update'}    | ${false}  | ${true}   | ${__('None')}
        ${'when editing and can update'}        | ${true}   | ${true}   | ${__('Enter a number')}
      `('$description', ({ isEditing, canUpdate, value }) => {
        it(`has a value of "${value}"`, async () => {
          createComponent({ canUpdate, isEditing });
          await nextTick();

          expect(findInput().attributes('placeholder')).toBe(value);
        });
      });
    });

    describe('readonly attribute', () => {
      describe.each`
        description             | canUpdate | value
        ${'when cannot update'} | ${false}  | ${'readonly'}
        ${'when can update'}    | ${true}   | ${undefined}
      `('$description', ({ canUpdate, value }) => {
        it(`renders readonly=${value}`, () => {
          createComponent({ canUpdate });

          expect(findInput().attributes('readonly')).toBe(value);
        });
      });
    });

    describe('value attribute', () => {
      describe.each`
        progress
        ${1}
        ${0}
        ${null}
        ${undefined}
      `('when `progress` prop is "$progress"', ({ progress }) => {
        it(`value is "${progress}"`, () => {
          createComponent({ progress });

          expect(wrapper.props().progress).toBe(progress);
        });
      });
    });

    describe('when blurred', () => {
      it('calls a mutation to update the weight when the input value is different', () => {
        const mutationSpy = jest.fn().mockResolvedValue(updateWorkItemMutationResponse);
        createComponent({
          isEditing: true,
          progress: 0,
          mutationHandler: mutationSpy,
          canUpdate: true,
        });

        findInput().vm.$emit('blur', { target: { value: 1 } });

        expect(mutationSpy).toHaveBeenCalledWith({
          input: {
            id: workItemId,
            progressWidget: {
              progress: 1,
            },
          },
        });
      });

      it('does not call a mutation to update the progress when the input value is the same', () => {
        const mutationSpy = jest.fn().mockResolvedValue(updateWorkItemMutationResponse);
        createComponent({ isEditing: true, mutationHandler: mutationSpy, canUpdate: true });

        findInput().trigger('blur');

        expect(mutationSpy).not.toHaveBeenCalledWith();
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
          isEditing: true,
          mutationHandler: jest.fn().mockResolvedValue(response),
          canUpdate: true,
        });

        findInput().trigger('blur');
        await waitForPromises();

        expect(wrapper.emitted('error')).toEqual([
          ['Something went wrong while updating the objective. Please try again.'],
        ]);
      });

      it('emits an error when there is a network error', async () => {
        createComponent({
          isEditing: true,
          mutationHandler: jest.fn().mockRejectedValue(new Error()),
          canUpdate: true,
        });

        findInput().trigger('blur');
        await waitForPromises();

        expect(wrapper.emitted('error')).toEqual([
          ['Something went wrong while updating the objective. Please try again.'],
        ]);
      });

      it('tracks updating the progress', () => {
        const trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
        createComponent({ canUpdate: true });

        findInput().trigger('blur');

        expect(trackingSpy).toHaveBeenCalledWith(TRACKING_CATEGORY_SHOW, 'updated_progress', {
          category: TRACKING_CATEGORY_SHOW,
          label: 'item_progress',
          property: 'type_Objective',
        });
      });
    });
  });

  it('calls the global ID work item query when `fetchByIid` prop is false', async () => {
    createComponent({ fetchByIid: false });
    await waitForPromises();

    expect(workItemQueryHandler).toHaveBeenCalled();
    expect(workItemByIidResponseHandler).not.toHaveBeenCalled();
  });

  it('calls the IID work item query when when `fetchByIid` prop is true', async () => {
    createComponent({ fetchByIid: true });
    await waitForPromises();

    expect(workItemQueryHandler).not.toHaveBeenCalled();
    expect(workItemByIidResponseHandler).toHaveBeenCalled();
  });

  it('skips calling the handlers when missing the needed queryVariables', async () => {
    createComponent({ queryVariables: {}, fetchByIid: false });
    await waitForPromises();

    expect(workItemQueryHandler).not.toHaveBeenCalled();
  });
});
