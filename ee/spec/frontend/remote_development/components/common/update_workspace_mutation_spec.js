import { shallowMount } from '@vue/test-utils';
import { cloneDeep } from 'lodash';
import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { logError } from '~/lib/logger';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPE_WORKSPACE } from '~/graphql_shared/constants';
import UpdateWorkspaceMutation, {
  i18n,
} from 'ee/remote_development/components/common/update_workspace_mutation.vue';
import workspaceUpdateMutation from 'ee/remote_development/graphql/mutations/workspace_update.mutation.graphql';
import { WORKSPACE_DESIRED_STATES } from 'ee/remote_development/constants';

import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import { WORKSPACE_UPDATE_MUTATION_RESULT, WORKSPACE } from '../../mock_data';

jest.mock('~/lib/logger');

Vue.use(VueApollo);

describe('remote_development/components/common/update_workspace_mutation.vue', () => {
  let workspaceUpdateMutationHandler;
  let updateWorkspaceSlotFunction;
  let wrapper;

  const createWrapper = () => {
    workspaceUpdateMutationHandler = jest.fn();

    const mockApollo = createMockApollo([
      [workspaceUpdateMutation, workspaceUpdateMutationHandler],
    ]);

    wrapper = shallowMount(UpdateWorkspaceMutation, {
      apolloProvider: mockApollo,
      scopedSlots: {
        default({ update }) {
          updateWorkspaceSlotFunction = update;
        },
      },
    });
  };

  describe('when update function is invoked', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('executes workspace update graphql mutation', () => {
      updateWorkspaceSlotFunction(WORKSPACE.id, { desiredState: WORKSPACE_DESIRED_STATES.running });

      expect(workspaceUpdateMutationHandler).toHaveBeenCalledWith({
        input: {
          desiredState: WORKSPACE_DESIRED_STATES.running,
          id: convertToGraphQLId(TYPE_WORKSPACE, WORKSPACE.id),
        },
      });
    });

    describe('when workspace update graphql mutation succeeds', () => {
      it('emits updateSucceed event', async () => {
        workspaceUpdateMutationHandler.mockResolvedValueOnce(WORKSPACE_UPDATE_MUTATION_RESULT);

        expect(wrapper.emitted('updateSucceed')).toBe(undefined);

        updateWorkspaceSlotFunction(WORKSPACE.id, {
          desiredState: WORKSPACE_DESIRED_STATES.running,
        });

        await waitForPromises();

        expect(wrapper.emitted('updateSucceed')).toHaveLength(1);
      });
    });

    describe('when the workspaceUpdate mutation returns an error response', () => {
      it('emits an updateFailed event', async () => {
        const errorMessage = 'Updating workspace failed';

        const errorResponse = cloneDeep(WORKSPACE_UPDATE_MUTATION_RESULT);

        errorResponse.data.workspaceUpdate.errors = [errorMessage];

        workspaceUpdateMutationHandler.mockReset();
        workspaceUpdateMutationHandler.mockResolvedValueOnce(errorResponse);

        updateWorkspaceSlotFunction(WORKSPACE.id, {
          desiredState: WORKSPACE_DESIRED_STATES.running,
        });

        await waitForPromises();

        expect(wrapper.emitted('updateFailed')[0]).toEqual([
          {
            error: errorMessage,
          },
        ]);
      });
    });

    describe('when the workspaceUpdate mutation fails', () => {
      const error = new Error();

      beforeEach(async () => {
        workspaceUpdateMutationHandler.mockReset();
        workspaceUpdateMutationHandler.mockRejectedValueOnce(error);

        updateWorkspaceSlotFunction(WORKSPACE.id, {
          desiredState: WORKSPACE_DESIRED_STATES.running,
        });

        await waitForPromises();
      });

      it('emits an updateFailed event', () => {
        expect(wrapper.emitted('updateFailed')[0]).toEqual([
          {
            error: i18n.updateWorkspaceFailedMessage,
          },
        ]);
      });

      it('logs the error', () => {
        expect(logError).toHaveBeenCalledWith(error);
      });
    });
  });
});
