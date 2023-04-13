import Vue from 'vue';
import { GlToggle } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import { s__ } from '~/locale';
import createMockApollo from 'helpers/mock_apollo_helper';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { staleTimeoutSecs } from 'jest/ci/runner/mock_data';

import groupStaleRunnerPruningQuery from 'ee/group_settings/graphql/group_stale_runner_pruning.query.graphql';
import setGroupStaleRunnerPruningMutation from 'ee/group_settings/graphql/set_group_stale_runner_pruning.mutation.graphql';
import StaleRunnerCleanupToggle from 'ee/group_settings/components/stale_runner_cleanup_toggle.vue';

Vue.use(VueApollo);

jest.mock('@sentry/browser');
jest.mock('~/alert');
jest.mock('~/ci/runner/sentry_utils');
jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal');

const mockGroupFullPath = 'group1';

describe('StaleRunnerCleanupToggle', () => {
  let wrapper;

  const pruningQueryHandler = jest.fn();
  const pruningMutationHandler = jest.fn();

  const findToggle = () => wrapper.findComponent(GlToggle);

  const mockPruningQueryHandler = ({ value = false, count = 0 } = {}) => {
    pruningQueryHandler.mockResolvedValueOnce({
      data: {
        group: {
          __typename: 'Group',
          id: 'gid://gitlab/Group/1',
          allowStaleRunnerPruning: value,
          runners: {
            __typename: 'CiRunnerConnection',
            count,
          },
        },
      },
    });
  };

  const mockPruningMutationHandler = ({ newValue = true, errors = [] } = {}) => {
    pruningMutationHandler.mockResolvedValueOnce({
      data: {
        namespaceCiCdSettingsUpdate: {
          __typename: 'NamespaceCiCdSettingsUpdatePayload',
          ciCdSettings: {
            __typename: 'NamespaceCiCdSetting',
            allowStaleRunnerPruning: newValue,
          },
          errors,
        },
      },
    });
  };

  const mockConfirmAction = ({ confirmed }) => {
    confirmAction.mockResolvedValueOnce(confirmed);
  };

  const createComponent = ({ mountFn = shallowMountExtended } = {}) => {
    const apolloProvider = createMockApollo([
      [groupStaleRunnerPruningQuery, pruningQueryHandler],
      [setGroupStaleRunnerPruningMutation, pruningMutationHandler],
    ]);

    wrapper = mountFn(StaleRunnerCleanupToggle, {
      propsData: {
        groupFullPath: mockGroupFullPath,
        staleTimeoutSecs,
      },
      apolloProvider,
    });
  };

  afterEach(() => {
    pruningQueryHandler.mockReset();
    pruningMutationHandler.mockReset();
    confirmAction.mockReset();
  });

  it('Displays a toggle in loading state', () => {
    mockPruningQueryHandler();
    createComponent();

    expect(findToggle().props()).toMatchObject({
      isLoading: true,
    });
  });

  it.each`
    value
    ${true}
    ${false}
  `('Displays a toggle set to "$value"', async ({ value }) => {
    mockPruningQueryHandler({ value });
    createComponent();
    await waitForPromises();

    expect(findToggle().props()).toMatchObject({
      value,
      isLoading: false,
    });
  });

  it('Display help message with stale timeout', () => {
    mockPruningQueryHandler();
    createComponent({ mountFn: mountExtended });

    expect(findToggle().text()).toMatch('3 months');
  });

  describe.each`
    count | message
    ${0}  | ${s__('Runners|This group currently has no stale runners.')}
    ${1}  | ${'1'}
    ${2}  | ${'2'}
  `('When there are $count stale runner(s)', ({ count, message }) => {
    beforeEach(async () => {
      mockPruningQueryHandler({ count });
      createComponent({ mountFn: mountExtended });

      await waitForPromises();
    });

    it(`confirmation message contains "${message}"`, () => {
      findToggle().vm.$emit('change', true);

      expect(confirmAction).toHaveBeenCalledWith(
        null,
        expect.objectContaining({
          modalHtmlMessage: expect.stringContaining(message),
        }),
      );
    });
  });

  describe('When setting is toggled', () => {
    const currentValue = false;
    const newValue = true;

    describe('when user confirms', () => {
      const confirmByUser = () => {
        mockPruningQueryHandler({ value: false });
        mockPruningMutationHandler({ newValue });

        createComponent();
      };

      it('shows loading state', async () => {
        await confirmByUser();

        mockConfirmAction({ confirmed: true });
        findToggle().vm.$emit('change', newValue);

        expect(findToggle().props('isLoading')).toBe(true);
      });

      it('saves the new setting', async () => {
        await confirmByUser();
        await waitForPromises();

        mockConfirmAction({ confirmed: true });
        findToggle().vm.$emit('change', newValue);

        await waitForPromises();
        expect(findToggle().props('isLoading')).toBe(false);
        expect(pruningMutationHandler).toHaveBeenCalledTimes(1);
        expect(pruningMutationHandler).toHaveBeenCalledWith({
          input: {
            fullPath: mockGroupFullPath,
            allowStaleRunnerPruning: newValue,
          },
        });
        expect(findToggle().props('value')).toBe(newValue);
      });
    });

    describe('when user does not confirm', () => {
      beforeEach(async () => {
        mockPruningQueryHandler({ value: false });
        mockPruningMutationHandler({ newValue });

        createComponent();
        await waitForPromises();

        mockConfirmAction({ confirmed: false });
        findToggle().vm.$emit('change', newValue);
      });

      it('does not save the setting', async () => {
        await waitForPromises();

        expect(pruningMutationHandler).toHaveBeenCalledTimes(0);
        expect(findToggle().props('value')).toBe(currentValue);
        expect(findToggle().props('isLoading')).toBe(false);
      });
    });
  });

  describe('When update fails', () => {
    const mockErrorMsg = 'Update error!';

    beforeEach(async () => {
      mockPruningQueryHandler();
      mockConfirmAction({ confirmed: true });

      createComponent();
      await waitForPromises();
    });

    describe('On a network error', () => {
      beforeEach(async () => {
        pruningMutationHandler.mockRejectedValueOnce(new Error(mockErrorMsg));
        findToggle().vm.$emit('change', true);

        await waitForPromises();
      });

      it('error is shown to the user and reported', () => {
        expect(createAlert).toHaveBeenCalledWith(
          expect.objectContaining({
            message: expect.any(String),
            captureError: true,
            error: new Error(mockErrorMsg),
          }),
        );
      });
    });

    describe('On a validation error', () => {
      beforeEach(async () => {
        mockPruningMutationHandler({ errors: [mockErrorMsg] });
        findToggle().vm.$emit('change', true);

        await waitForPromises();
      });

      it('error is shown to the user and reported', () => {
        expect(createAlert).toHaveBeenCalledWith(
          expect.objectContaining({
            message: expect.any(String),
            captureError: true,
            error: new Error(mockErrorMsg),
          }),
        );
      });
    });
  });
});
