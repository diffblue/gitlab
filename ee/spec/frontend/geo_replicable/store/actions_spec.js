import {
  ACTION_TYPES,
  PREV,
  NEXT,
  DEFAULT_PAGE_SIZE,
  FILTER_OPTIONS,
} from 'ee/geo_replicable/constants';
import buildReplicableTypeQuery from 'ee/geo_replicable/graphql/replicable_type_query_builder';
import replicableTypeUpdateMutation from 'ee/geo_replicable/graphql/replicable_type_update_mutation.graphql';
import replicableTypeBulkUpdateMutation from 'ee/geo_replicable/graphql/replicable_type_bulk_update_mutation.graphql';
import * as actions from 'ee/geo_replicable/store/actions';
import * as types from 'ee/geo_replicable/store/mutation_types';
import createState from 'ee/geo_replicable/store/state';
import testAction from 'helpers/vuex_action_helper';
import { createAlert } from '~/alert';
import toast from '~/vue_shared/plugins/global_toast';
import {
  MOCK_REPLICABLE_TYPE,
  MOCK_BASIC_GRAPHQL_QUERY_RESPONSE,
  MOCK_BASIC_GRAPHQL_DATA,
  MOCK_GRAPHQL_PAGINATION_DATA,
  MOCK_GRAPHQL_REGISTRY,
  MOCK_GRAPHQL_REGISTRY_CLASS,
} from '../mock_data';

jest.mock('~/alert');
jest.mock('~/vue_shared/plugins/global_toast');

const mockGeoGqClient = { query: jest.fn(), mutate: jest.fn() };
jest.mock('ee/geo_replicable/utils', () => ({
  ...jest.requireActual('ee/geo_replicable/utils'),
  getGraphqlClient: jest.fn().mockImplementation(() => mockGeoGqClient),
}));

describe('GeoReplicable Store Actions', () => {
  let state;

  beforeEach(() => {
    state = createState({
      replicableType: MOCK_REPLICABLE_TYPE,
      graphqlFieldName: MOCK_GRAPHQL_REGISTRY,
      graphqlMutationRegistryClass: MOCK_GRAPHQL_REGISTRY_CLASS,
      geoCurrentSiteId: null,
      geoTargetSiteId: null,
      verificationEnabled: 'true',
    });
  });

  // Fetch Replicable Items

  describe('requestReplicableItems', () => {
    it('should commit mutation REQUEST_REPLICABLE_ITEMS', async () => {
      await testAction(
        actions.requestReplicableItems,
        null,
        state,
        [{ type: types.REQUEST_REPLICABLE_ITEMS }],
        [],
      );
    });
  });

  describe('receiveReplicableItemsSuccess', () => {
    it('should commit mutation RECEIVE_REPLICABLE_ITEMS_SUCCESS', async () => {
      await testAction(
        actions.receiveReplicableItemsSuccess,
        { data: MOCK_BASIC_GRAPHQL_DATA, pagination: MOCK_GRAPHQL_PAGINATION_DATA },
        state,
        [
          {
            type: types.RECEIVE_REPLICABLE_ITEMS_SUCCESS,
            payload: { data: MOCK_BASIC_GRAPHQL_DATA, pagination: MOCK_GRAPHQL_PAGINATION_DATA },
          },
        ],
        [],
      );
    });
  });

  describe('receiveReplicableItemsError', () => {
    it('should commit mutation RECEIVE_REPLICABLE_ITEMS_ERROR', async () => {
      await testAction(
        actions.receiveReplicableItemsError,
        null,
        state,
        [{ type: types.RECEIVE_REPLICABLE_ITEMS_ERROR }],
        [],
        () => {
          expect(createAlert).toHaveBeenCalledTimes(1);
        },
      );
    });
  });

  describe('fetchReplicableItems', () => {
    describe.each`
      geoCurrentSiteId | geoTargetSiteId
      ${2}             | ${3}
      ${2}             | ${2}
      ${undefined}     | ${2}
      ${undefined}     | ${undefined}
      ${2}             | ${undefined}
    `(`geoSiteIds`, ({ geoCurrentSiteId, geoTargetSiteId }) => {
      beforeEach(() => {
        state.graphqlFieldName = MOCK_GRAPHQL_REGISTRY;
        state.geoCurrentSiteId = geoCurrentSiteId;
        state.geoTargetSiteId = geoTargetSiteId;
      });

      describe('on success with no registry data', () => {
        beforeEach(() => {
          jest.spyOn(mockGeoGqClient, 'query').mockResolvedValue({
            data: {},
          });
        });

        const direction = null;
        const data = [];

        it('should not error and pass empty values to the mutations', () => {
          testAction(
            actions.fetchReplicableItems,
            direction,
            state,
            [],
            [
              { type: 'requestReplicableItems' },
              {
                type: 'receiveReplicableItemsSuccess',
                payload: { data, pagination: null },
              },
            ],
            () => {
              expect(mockGeoGqClient.query).toHaveBeenCalledWith({
                query: buildReplicableTypeQuery(MOCK_GRAPHQL_REGISTRY, true),
                variables: { before: '', after: '', first: DEFAULT_PAGE_SIZE, last: null },
              });
            },
          );
        });
      });

      describe('on success', () => {
        beforeEach(() => {
          jest.spyOn(mockGeoGqClient, 'query').mockResolvedValue({
            data: MOCK_BASIC_GRAPHQL_QUERY_RESPONSE,
          });
          state.paginationData = MOCK_GRAPHQL_PAGINATION_DATA;
          state.paginationData.page = 1;
        });

        describe('with no direction set', () => {
          const direction = null;
          // Query.geoNode to be renamed to Query.geoSite => https://gitlab.com/gitlab-org/gitlab/-/issues/396739
          const registries = MOCK_BASIC_GRAPHQL_QUERY_RESPONSE.geoNode[MOCK_GRAPHQL_REGISTRY];
          const data = registries.nodes;

          it('should call mockGeoGqClient with no before/after variables as well as a first variable but no last variable', () => {
            testAction(
              actions.fetchReplicableItems,
              direction,
              state,
              [],
              [
                { type: 'requestReplicableItems' },
                {
                  type: 'receiveReplicableItemsSuccess',
                  payload: { data, pagination: registries.pageInfo },
                },
              ],
              () => {
                expect(mockGeoGqClient.query).toHaveBeenCalledWith({
                  query: buildReplicableTypeQuery(MOCK_GRAPHQL_REGISTRY, true),
                  variables: { before: '', after: '', first: DEFAULT_PAGE_SIZE, last: null },
                });
              },
            );
          });
        });

        describe('with direction set to "next"', () => {
          const direction = NEXT;
          // Query.geoNode to be renamed to Query.geoSite => https://gitlab.com/gitlab-org/gitlab/-/issues/396739
          const registries = MOCK_BASIC_GRAPHQL_QUERY_RESPONSE.geoNode[MOCK_GRAPHQL_REGISTRY];
          const data = registries.nodes;

          it('should call mockGeoGqClient with after variable but no before variable as well as a first variable but no last variable', () => {
            testAction(
              actions.fetchReplicableItems,
              direction,
              state,
              [],
              [
                { type: 'requestReplicableItems' },
                {
                  type: 'receiveReplicableItemsSuccess',
                  payload: { data, pagination: registries.pageInfo },
                },
              ],
              () => {
                expect(mockGeoGqClient.query).toHaveBeenCalledWith({
                  query: buildReplicableTypeQuery(MOCK_GRAPHQL_REGISTRY, true),
                  variables: {
                    before: '',
                    after: MOCK_GRAPHQL_PAGINATION_DATA.endCursor,
                    first: DEFAULT_PAGE_SIZE,
                    last: null,
                  },
                });
              },
            );
          });
        });

        describe('with direction set to "prev"', () => {
          const direction = PREV;
          // Query.geoNode to be renamed to Query.geoSite => https://gitlab.com/gitlab-org/gitlab/-/issues/396739
          const registries = MOCK_BASIC_GRAPHQL_QUERY_RESPONSE.geoNode[MOCK_GRAPHQL_REGISTRY];
          const data = registries.nodes;

          it('should call mockGeoGqClient with before variable but no after variable as well as a last variable but no first variable', () => {
            testAction(
              actions.fetchReplicableItems,
              direction,
              state,
              [],
              [
                { type: 'requestReplicableItems' },
                {
                  type: 'receiveReplicableItemsSuccess',
                  payload: { data, pagination: registries.pageInfo },
                },
              ],
              () => {
                expect(mockGeoGqClient.query).toHaveBeenCalledWith({
                  query: buildReplicableTypeQuery(MOCK_GRAPHQL_REGISTRY, true),
                  variables: {
                    before: MOCK_GRAPHQL_PAGINATION_DATA.startCursor,
                    after: '',
                    first: null,
                    last: DEFAULT_PAGE_SIZE,
                  },
                });
              },
            );
          });
        });

        describe('with statusFilter', () => {
          const direction = null;
          // Query.geoNode to be renamed to Query.geoSite => https://gitlab.com/gitlab-org/gitlab/-/issues/396739
          const registries = MOCK_BASIC_GRAPHQL_QUERY_RESPONSE.geoNode[MOCK_GRAPHQL_REGISTRY];
          const data = registries.nodes;

          it('should call mockGeoGqClient with all uppercase replicationState', () => {
            state.statusFilter = FILTER_OPTIONS[1].value;

            testAction(
              actions.fetchReplicableItems,
              direction,
              state,
              [],
              [
                { type: 'requestReplicableItems' },
                {
                  type: 'receiveReplicableItemsSuccess',
                  payload: { data, pagination: registries.pageInfo },
                },
              ],
              () => {
                expect(mockGeoGqClient.query).toHaveBeenCalledWith({
                  query: buildReplicableTypeQuery(MOCK_GRAPHQL_REGISTRY, true),
                  variables: {
                    before: '',
                    after: '',
                    first: DEFAULT_PAGE_SIZE,
                    last: null,
                    replicationState: FILTER_OPTIONS[1].value.toUpperCase(),
                  },
                });
              },
            );
          });
        });
      });

      describe('on error', () => {
        beforeEach(() => {
          jest.spyOn(mockGeoGqClient, 'query').mockRejectedValue();
        });

        it('should dispatch the request and error actions', async () => {
          await testAction(
            actions.fetchReplicableItems,
            null,
            state,
            [],
            [{ type: 'requestReplicableItems' }, { type: 'receiveReplicableItemsError' }],
          );
        });
      });
    });
  });

  // All Replicable Action

  describe('requestInitiateAllReplicableAction', () => {
    it('should commit mutation REQUEST_INITIATE_ALL_REPLICABLE_ACTION', async () => {
      await testAction(
        actions.requestInitiateAllReplicableAction,
        null,
        state,
        [{ type: types.REQUEST_INITIATE_ALL_REPLICABLE_ACTION }],
        [],
      );
    });
  });

  describe('receiveInitiateAllReplicableActionSuccess', () => {
    it('should commit mutation RECEIVE_INITIATE_ALL_REPLICABLE_ACTION_SUCCESS and call fetchReplicableItems and toast', async () => {
      await testAction(
        actions.receiveInitiateAllReplicableActionSuccess,
        { action: ACTION_TYPES.RESYNC_ALL },
        state,
        [{ type: types.RECEIVE_INITIATE_ALL_REPLICABLE_ACTION_SUCCESS }],
        [{ type: 'fetchReplicableItems' }],
        () => {
          expect(toast).toHaveBeenCalledTimes(1);
          toast.mockClear();
        },
      );
    });
  });

  describe('receiveInitiateAllReplicableActionError', () => {
    it('should commit mutation RECEIVE_INITIATE_ALL_REPLICABLE_ACTION_ERROR', () => {
      testAction(
        actions.receiveInitiateAllReplicableActionError,
        { action: ACTION_TYPES.RESYNC_ALL },
        state,
        [{ type: types.RECEIVE_INITIATE_ALL_REPLICABLE_ACTION_ERROR }],
        [],
        () => {
          expect(createAlert).toHaveBeenCalledTimes(1);
        },
      );
    });
  });

  describe('All Replicable Action', () => {
    const action = ACTION_TYPES.RESYNC_ALL;

    describe('initiateAllReplicableAction', () => {
      describe('on success', () => {
        beforeEach(() => {
          jest.spyOn(mockGeoGqClient, 'mutate').mockResolvedValue({});
        });

        it('should call mockGeoClient with correct parameters and success actions', () => {
          testAction(
            actions.initiateAllReplicableAction,
            { action },
            state,
            [],
            [
              { type: 'requestInitiateAllReplicableAction' },
              {
                type: 'receiveInitiateAllReplicableActionSuccess',
                payload: { action },
              },
            ],
            () => {
              expect(mockGeoGqClient.query).toHaveBeenCalledWith({
                mutate: replicableTypeBulkUpdateMutation,
                variables: {
                  action: action.toUpperCase(),
                },
              });
            },
          );
        });
      });

      describe('on error', () => {
        beforeEach(() => {
          jest.spyOn(mockGeoGqClient, 'mutate').mockRejectedValue({});
        });

        it('should call mockGeoClient with correct parameters and error actions', () => {
          testAction(
            actions.initiateAllReplicableAction,
            { action },
            state,
            [],
            [
              { type: 'requestInitiateAllReplicableAction' },
              {
                type: 'receiveInitiateAllReplicableActionError',
                payload: { action },
              },
            ],
            () => {
              expect(mockGeoGqClient.query).toHaveBeenCalledWith({
                mutate: replicableTypeBulkUpdateMutation,
                variables: {
                  action: action.toUpperCase(),
                },
              });
            },
          );
        });
      });
    });
  });

  // Single Replicable Action

  describe('requestInitiateReplicableAction', () => {
    it('should commit mutation REQUEST_INITIATE_REPLICABLE_ACTION', async () => {
      await testAction(
        actions.requestInitiateReplicableAction,
        null,
        state,
        [{ type: types.REQUEST_INITIATE_REPLICABLE_ACTION }],
        [],
      );
    });
  });

  describe('receiveInitiateReplicableActionSuccess', () => {
    it('should commit mutation RECEIVE_INITIATE_REPLICABLE_ACTION_SUCCESS and call fetchReplicableItems and toast', async () => {
      await testAction(
        actions.receiveInitiateReplicableActionSuccess,
        { action: ACTION_TYPES.RESYNC, name: 'test' },
        state,
        [{ type: types.RECEIVE_INITIATE_REPLICABLE_ACTION_SUCCESS }],
        [{ type: 'fetchReplicableItems' }],
      );
      expect(toast).toHaveBeenCalledTimes(1);
      toast.mockClear();
    });
  });

  describe('receiveInitiateReplicableActionError', () => {
    it('should commit mutation RECEIVE_INITIATE_REPLICABLE_ACTION_ERROR', async () => {
      await testAction(
        actions.receiveInitiateReplicableActionError,
        { action: ACTION_TYPES.RESYNC, registryId: 1, name: 'test' },
        state,
        [{ type: types.RECEIVE_INITIATE_REPLICABLE_ACTION_ERROR }],
        [],
      );
      expect(createAlert).toHaveBeenCalledTimes(1);
    });
  });

  describe('Replicable Action', () => {
    const action = ACTION_TYPES.RESYNC;
    const registryId = 1;
    const name = 'test';

    describe('initiateReplicableAction', () => {
      describe('on success', () => {
        beforeEach(() => {
          jest.spyOn(mockGeoGqClient, 'mutate').mockResolvedValue({});
        });

        it('should call mockGeoClient with correct parameters and success actions', () => {
          testAction(
            actions.initiateReplicableAction,
            { registryId, name, action },
            state,
            [],
            [
              { type: 'requestInitiateReplicableAction' },
              {
                type: 'receiveInitiateReplicableActionSuccess',
                payload: { name, action },
              },
            ],
            () => {
              expect(mockGeoGqClient.query).toHaveBeenCalledWith({
                mutate: replicableTypeUpdateMutation,
                variables: {
                  action: action.toUpperCase(),
                  registryId,
                  registryClass: MOCK_GRAPHQL_REGISTRY_CLASS,
                },
              });
            },
          );
        });
      });

      describe('on error', () => {
        beforeEach(() => {
          jest.spyOn(mockGeoGqClient, 'mutate').mockRejectedValue({});
        });

        it('should call mockGeoClient with correct parameters and error actions', () => {
          testAction(
            actions.initiateReplicableAction,
            { registryId, name, action },
            state,
            [],
            [
              { type: 'requestInitiateReplicableAction' },
              {
                type: 'receiveInitiateReplicableActionError',
                payload: { name },
              },
            ],
            () => {
              expect(mockGeoGqClient.query).toHaveBeenCalledWith({
                mutate: replicableTypeUpdateMutation,
                variables: {
                  action: action.toUpperCase(),
                  registryId,
                  registryClass: MOCK_GRAPHQL_REGISTRY_CLASS,
                },
              });
            },
          );
        });
      });
    });
  });

  describe('setStatusFilter', () => {
    it('should commit mutation SET_STATUS_FILTER', async () => {
      const testValue = FILTER_OPTIONS[1].value;

      await testAction(
        actions.setStatusFilter,
        testValue,
        state,
        [{ type: types.SET_STATUS_FILTER, payload: testValue }],
        [],
      );
    });
  });

  describe('setSearch', () => {
    it('should commit mutation SET_SEARCH', async () => {
      const testValue = 'Test Search';

      await testAction(
        actions.setSearch,
        testValue,
        state,
        [{ type: types.SET_SEARCH, payload: testValue }],
        [],
      );
    });
  });
});
