import Api from 'ee/api';
import * as actions from 'ee/vue_shared/components/sidebar/epics_select/store/actions';
import * as types from 'ee/vue_shared/components/sidebar/epics_select/store/mutation_types';
import createDefaultState from 'ee/vue_shared/components/sidebar/epics_select/store/state';
import { noneEpic } from 'ee/vue_shared/constants';
import testAction from 'helpers/vuex_action_helper';
import createFlash from '~/flash';

import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

import { mockEpic1, mockIssue, mockEpics, mockAssignRemoveRes } from '../../mock_data';

jest.mock('~/flash');

describe('EpicsSelect', () => {
  describe('store', () => {
    describe('actions', () => {
      let state;
      const normalizedEpics = mockEpics.map((rawEpic) =>
        convertObjectPropsToCamelCase(Object.assign(rawEpic, { url: rawEpic.web_edit_url }), {
          dropKeys: ['web_edit_url'],
        }),
      );

      beforeEach(() => {
        state = createDefaultState();
      });

      describe('setInitialData', () => {
        it('should set initial data on state', async () => {
          const mockInitialConfig = {
            groupId: mockEpic1.group_id,
            issueId: mockIssue.id,
            selectedEpic: mockEpic1,
            selectedEpicIssueId: mockIssue.epic_issue_id,
          };

          await testAction(
            actions.setInitialData,
            mockInitialConfig,
            state,
            [{ type: types.SET_INITIAL_DATA, payload: mockInitialConfig }],
            [],
          );
        });
      });

      describe('setIssueId', () => {
        it('should set `issueId` on state', async () => {
          const issueId = mockIssue.id;

          await testAction(
            actions.setIssueId,
            issueId,
            state,
            [{ type: types.SET_ISSUE_ID, payload: issueId }],
            [],
          );
        });
      });

      describe('setSearchQuery', () => {
        it('should set `searchQuery` param on state', async () => {
          const searchQuery = 'foo';

          await testAction(
            actions.setSearchQuery,
            searchQuery,
            state,
            [{ type: types.SET_SEARCH_QUERY, payload: searchQuery }],
            [],
          );
        });
      });

      describe('setSelectedEpic', () => {
        it('should set `selectedEpic` param on state', async () => {
          await testAction(
            actions.setSelectedEpic,
            mockEpic1,
            state,
            [{ type: types.SET_SELECTED_EPIC, payload: mockEpic1 }],
            [],
          );
        });
      });

      describe('setSelectedEpicIssueId', () => {
        it('should set `selectedEpicIssueId` param on state', async () => {
          await testAction(
            actions.setSelectedEpicIssueId,
            mockIssue.epic_issue_id,
            state,
            [{ type: types.SET_SELECTED_EPIC_ISSUE_ID, payload: mockIssue.epic_issue_id }],
            [],
          );
        });
      });

      describe('requestEpics', () => {
        it('should set `state.epicsFetchInProgress` to true', async () => {
          await testAction(actions.requestEpics, {}, state, [{ type: types.REQUEST_EPICS }], []);
        });
      });

      describe('receiveEpicsSuccess', () => {
        it('should set processed Epics array to `state.epics`', async () => {
          state.groupId = mockEpic1.group_id;

          await testAction(
            actions.receiveEpicsSuccess,
            mockEpics,
            state,
            [{ type: types.RECEIVE_EPICS_SUCCESS, payload: { epics: normalizedEpics } }],
            [],
          );
        });
      });

      describe('receiveEpicsFailure', () => {
        it('should show flash error message', () => {
          actions.receiveEpicsFailure({
            commit: () => {},
          });

          expect(createFlash).toHaveBeenCalledWith({
            message: 'Something went wrong while fetching group epics.',
          });
        });

        it('should set `state.epicsFetchInProgress` to false', async () => {
          await testAction(
            actions.receiveEpicsFailure,
            {},
            state,
            [{ type: types.RECEIVE_EPICS_FAILURE }],
            [],
          );
        });
      });

      describe('fetchEpics', () => {
        beforeAll(() => {
          state.groupId = mockEpic1.group_id;
        });

        it('should dispatch `requestEpics` & call `Api.groupEpics` and then dispatch `receiveEpicsSuccess` on request success', async () => {
          jest.spyOn(Api, 'groupEpics').mockReturnValue(
            Promise.resolve({
              data: mockEpics,
            }),
          );

          await testAction(
            actions.fetchEpics,
            mockEpics,
            state,
            [],
            [
              {
                type: 'requestEpics',
              },
              {
                type: 'receiveEpicsSuccess',
                payload: mockEpics,
              },
            ],
          );
        });

        it('should dispatch `requestEpics` & call `Api.groupEpics` and then dispatch `receiveEpicsFailure` on request failure', async () => {
          jest.spyOn(Api, 'groupEpics').mockReturnValue(Promise.reject());

          await testAction(
            actions.fetchEpics,
            mockEpics,
            state,
            [],
            [
              {
                type: 'requestEpics',
              },
              {
                type: 'receiveEpicsFailure',
              },
            ],
          );
        });

        it('should call `Api.groupEpics` with `groupId` as param from state', () => {
          jest.spyOn(Api, 'groupEpics').mockReturnValue(
            Promise.resolve({
              data: mockEpics,
            }),
          );

          actions.fetchEpics(
            {
              state,
              dispatch: () => {},
            },
            'foo',
          );

          expect(Api.groupEpics).toHaveBeenCalledWith({
            groupId: state.groupId,
            includeDescendantGroups: false,
            includeAncestorGroups: true,
            search: 'foo',
          });
        });
      });

      describe('requestIssueUpdate', () => {
        it('should set `state.epicSelectInProgress` to true', async () => {
          await testAction(
            actions.requestIssueUpdate,
            {},
            state,
            [{ type: types.REQUEST_ISSUE_UPDATE }],
            [],
          );
        });
      });

      describe('receiveIssueUpdateSuccess', () => {
        it('should set updated selectedEpic with passed Epic instance to state when payload has matching Epic and Issue IDs', async () => {
          state.issueId = mockIssue.id;

          await testAction(
            actions.receiveIssueUpdateSuccess,
            {
              data: mockAssignRemoveRes,
              epic: normalizedEpics[0],
            },
            state,
            [
              {
                type: types.RECEIVE_ISSUE_UPDATE_SUCCESS,
                payload: {
                  selectedEpic: normalizedEpics[0],
                  selectedEpicIssueId: mockAssignRemoveRes.id,
                },
              },
            ],
            [],
          );
        });

        it('should set updated selectedEpic with noneEpic to state when payload has matching Epic and Issue IDs and isRemoval param is true', async () => {
          state.issueId = mockIssue.id;

          await testAction(
            actions.receiveIssueUpdateSuccess,
            {
              data: mockAssignRemoveRes,
              epic: normalizedEpics[0],
              isRemoval: true,
            },
            state,
            [
              {
                type: types.RECEIVE_ISSUE_UPDATE_SUCCESS,
                payload: {
                  selectedEpic: noneEpic,
                  selectedEpicIssueId: mockAssignRemoveRes.id,
                },
              },
            ],
            [],
          );
        });

        it('should not do any mutation to the state whe payload does not have matching Epic and Issue IDs', async () => {
          await testAction(
            actions.receiveIssueUpdateSuccess,
            {
              data: mockAssignRemoveRes,
              epic: normalizedEpics[1],
            },
            state,
            [],
            [],
          );
        });
      });

      describe('receiveIssueUpdateFailure', () => {
        it('should show flash error message', () => {
          const message = 'Something went wrong.';
          actions.receiveIssueUpdateFailure(
            {
              commit: () => {},
            },
            message,
          );

          expect(createFlash).toHaveBeenCalledWith({ message });
        });

        it('should set `state.epicSelectInProgress` to false', async () => {
          await testAction(
            actions.receiveIssueUpdateFailure,
            {},
            state,
            [{ type: types.RECEIVE_ISSUE_UPDATE_FAILURE }],
            [],
          );
        });
      });

      describe('assignIssueToEpic', () => {
        beforeAll(() => {
          state.issueId = mockIssue.id;
        });

        it('should dispatch `requestIssueUpdate` & call `Api.addEpicIssue` and then dispatch `receiveIssueUpdateSuccess` on request success', async () => {
          jest.spyOn(Api, 'addEpicIssue').mockReturnValue(
            Promise.resolve({
              data: mockAssignRemoveRes,
            }),
          );

          await testAction(
            actions.assignIssueToEpic,
            normalizedEpics[0],
            state,
            [],
            [
              {
                type: 'requestIssueUpdate',
              },
              {
                type: 'receiveIssueUpdateSuccess',
                payload: { data: mockAssignRemoveRes, epic: normalizedEpics[0] },
              },
            ],
          );
        });

        it('should dispatch `requestIssueUpdate` & call `Api.addEpicIssue` and then dispatch `receiveIssueUpdateFailure` on request failure', async () => {
          jest.spyOn(Api, 'addEpicIssue').mockReturnValue(Promise.reject());

          await testAction(
            actions.assignIssueToEpic,
            normalizedEpics[0],
            state,
            [],
            [
              {
                type: 'requestIssueUpdate',
              },
              {
                type: 'receiveIssueUpdateFailure',
                payload: 'Something went wrong while assigning issue to epic.',
              },
            ],
          );
        });

        it('should call `Api.addEpicIssue` with `issueId`, `groupId` and `epicIid` as params', () => {
          jest.spyOn(Api, 'addEpicIssue').mockReturnValue(
            Promise.resolve({
              data: mockAssignRemoveRes,
            }),
          );

          actions.assignIssueToEpic(
            {
              state,
              dispatch: () => {},
            },
            normalizedEpics[0],
          );

          expect(Api.addEpicIssue).toHaveBeenCalledWith({
            issueId: state.issueId,
            groupId: normalizedEpics[0].groupId,
            epicIid: normalizedEpics[0].iid,
          });
        });
      });

      describe('removeIssueFromEpic', () => {
        beforeAll(() => {
          state.selectedEpicIssueId = mockIssue.epic_issue_id;
        });

        it('should dispatch `requestIssueUpdate` & call `Api.removeEpicIssue` and then dispatch `receiveIssueUpdateSuccess` on request success', async () => {
          jest.spyOn(Api, 'removeEpicIssue').mockReturnValue(
            Promise.resolve({
              data: mockAssignRemoveRes,
            }),
          );

          await testAction(
            actions.removeIssueFromEpic,
            normalizedEpics[0],
            state,
            [],
            [
              {
                type: 'requestIssueUpdate',
              },
              {
                type: 'receiveIssueUpdateSuccess',
                payload: { data: mockAssignRemoveRes, epic: normalizedEpics[0], isRemoval: true },
              },
            ],
          );
        });

        it('should dispatch `requestIssueUpdate` & call `Api.removeEpicIssue` and then dispatch `receiveIssueUpdateFailure` on request failure', async () => {
          jest.spyOn(Api, 'removeEpicIssue').mockReturnValue(Promise.reject());

          await testAction(
            actions.removeIssueFromEpic,
            normalizedEpics[0],
            state,
            [],
            [
              {
                type: 'requestIssueUpdate',
              },
              {
                type: 'receiveIssueUpdateFailure',
                payload: 'Something went wrong while removing issue from epic.',
              },
            ],
          );
        });

        it('should call `Api.removeEpicIssue` with `epicIssueId`, `groupId` and `epicIid` as params', () => {
          jest.spyOn(Api, 'removeEpicIssue').mockReturnValue(
            Promise.resolve({
              data: mockAssignRemoveRes,
            }),
          );

          actions.removeIssueFromEpic(
            {
              state,
              dispatch: () => {},
            },
            normalizedEpics[0],
          );

          expect(Api.removeEpicIssue).toHaveBeenCalledWith({
            epicIssueId: state.selectedEpicIssueId,
            groupId: normalizedEpics[0].groupId,
            epicIid: normalizedEpics[0].iid,
          });
        });
      });
    });
  });
});
