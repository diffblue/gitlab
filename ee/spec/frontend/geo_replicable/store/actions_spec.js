import Api from 'ee/api';
import { ACTION_TYPES, PREV, NEXT, DEFAULT_PAGE_SIZE } from 'ee/geo_replicable/constants';
import buildReplicableTypeQuery from 'ee/geo_replicable/graphql/replicable_type_query_builder';
import * as actions from 'ee/geo_replicable/store/actions';
import * as types from 'ee/geo_replicable/store/mutation_types';
import createState from 'ee/geo_replicable/store/state';
import testAction from 'helpers/vuex_action_helper';
import { createAlert } from '~/alert';
import { normalizeHeaders, parseIntPagination } from '~/lib/utils/common_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR } from '~/lib/utils/http_status';
import toast from '~/vue_shared/plugins/global_toast';
import {
  MOCK_BASIC_FETCH_DATA_MAP,
  MOCK_BASIC_FETCH_RESPONSE,
  MOCK_BASIC_POST_RESPONSE,
  MOCK_REPLICABLE_TYPE,
  MOCK_RESTFUL_PAGINATION_DATA,
  MOCK_BASIC_GRAPHQL_QUERY_RESPONSE,
  MOCK_GRAPHQL_PAGINATION_DATA,
  MOCK_GRAPHQL_REGISTRY,
} from '../mock_data';

jest.mock('~/alert');
jest.mock('~/vue_shared/plugins/global_toast');

const mockGeoGqClient = { query: jest.fn() };
jest.mock('ee/geo_replicable/utils', () => ({
  ...jest.requireActual('ee/geo_replicable/utils'),
  getGraphqlClient: jest.fn().mockImplementation(() => mockGeoGqClient),
}));

describe('GeoReplicable Store Actions', () => {
  let state;

  beforeEach(() => {
    state = createState({
      replicableType: MOCK_REPLICABLE_TYPE,
      graphqlFieldName: null,
      geoCurrentSiteId: null,
      geoTargetSiteId: null,
      verificationEnabled: 'true',
    });
  });

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
        { data: MOCK_BASIC_FETCH_DATA_MAP, pagination: MOCK_RESTFUL_PAGINATION_DATA },
        state,
        [
          {
            type: types.RECEIVE_REPLICABLE_ITEMS_SUCCESS,
            payload: { data: MOCK_BASIC_FETCH_DATA_MAP, pagination: MOCK_RESTFUL_PAGINATION_DATA },
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
    describe('with graphql', () => {
      beforeEach(() => {
        state.useGraphQl = true;
      });

      it('calls fetchReplicableItemsGraphQl', async () => {
        await testAction(
          actions.fetchReplicableItems,
          null,
          state,
          [],
          [
            { type: 'requestReplicableItems' },
            { type: 'fetchReplicableItemsGraphQl', payload: null },
          ],
        );
      });
    });

    describe('without graphql', () => {
      beforeEach(() => {
        state.useGraphQl = false;
      });

      it('calls fetchReplicableItemsRestful', async () => {
        await testAction(
          actions.fetchReplicableItems,
          null,
          state,
          [],
          [{ type: 'requestReplicableItems' }, { type: 'fetchReplicableItemsRestful' }],
        );
      });
    });
  });

  describe('fetchReplicableItemsGraphQl', () => {
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
            actions.fetchReplicableItemsGraphQl,
            direction,
            state,
            [],
            [
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
              actions.fetchReplicableItemsGraphQl,
              direction,
              state,
              [],
              [
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
              actions.fetchReplicableItemsGraphQl,
              direction,
              state,
              [],
              [
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
              actions.fetchReplicableItemsGraphQl,
              direction,
              state,
              [],
              [
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
      });

      describe('on error', () => {
        beforeEach(() => {
          jest.spyOn(mockGeoGqClient, 'query').mockRejectedValue();
        });

        it('should dispatch the request and error actions', async () => {
          await testAction(
            actions.fetchReplicableItemsGraphQl,
            null,
            state,
            [],
            [{ type: 'receiveReplicableItemsError' }],
          );
        });
      });
    });
  });

  describe('fetchReplicableItemsRestful', () => {
    const normalizedHeaders = normalizeHeaders(MOCK_BASIC_FETCH_RESPONSE.headers);
    const pagination = parseIntPagination(normalizedHeaders);

    describe('on success', () => {
      beforeEach(() => {
        jest.spyOn(Api, 'getGeoReplicableItems').mockResolvedValue(MOCK_BASIC_FETCH_RESPONSE);
      });

      describe('with no params set', () => {
        const defaultParams = {
          page: 1,
          search: null,
          sync_status: null,
        };

        it('should call getGeoReplicableItems with default queryParams', () => {
          testAction(
            actions.fetchReplicableItemsRestful,
            {},
            state,
            [],
            [
              {
                type: 'receiveReplicableItemsSuccess',
                payload: { data: MOCK_BASIC_FETCH_DATA_MAP, pagination },
              },
            ],
            () => {
              expect(Api.getGeoReplicableItems).toHaveBeenCalledWith(
                MOCK_REPLICABLE_TYPE,
                defaultParams,
              );
            },
          );
        });
      });

      describe('with params set', () => {
        beforeEach(() => {
          state.paginationData.page = 3;
          state.searchFilter = 'test search';
          state.currentFilterIndex = 2;
        });

        it('should call getGeoReplicableItems with default queryParams', () => {
          testAction(
            actions.fetchReplicableItemsRestful,
            {},
            state,
            [],
            [
              {
                type: 'receiveReplicableItemsSuccess',
                payload: { data: MOCK_BASIC_FETCH_DATA_MAP, pagination },
              },
            ],
            () => {
              expect(Api.getGeoReplicableItems).toHaveBeenCalledWith(MOCK_REPLICABLE_TYPE, {
                page: 3,
                search: 'test search',
                sync_status: state.filterOptions[2].value,
              });
            },
          );
        });
      });
    });

    describe('on error', () => {
      beforeEach(() => {
        jest
          .spyOn(Api, 'getGeoReplicableItems')
          .mockRejectedValue(new Error(HTTP_STATUS_INTERNAL_SERVER_ERROR));
      });

      it('should dispatch the request and error actions', async () => {
        await testAction(
          actions.fetchReplicableItemsRestful,
          {},
          state,
          [],
          [{ type: 'receiveReplicableItemsError' }],
        );
      });
    });
  });

  describe('requestInitiateAllReplicableSyncs', () => {
    it('should commit mutation REQUEST_INITIATE_ALL_REPLICABLE_SYNCS', async () => {
      await testAction(
        actions.requestInitiateAllReplicableSyncs,
        null,
        state,
        [{ type: types.REQUEST_INITIATE_ALL_REPLICABLE_SYNCS }],
        [],
      );
    });
  });

  describe('receiveInitiateAllReplicableSyncsSuccess', () => {
    it('should commit mutation RECEIVE_INITIATE_ALL_REPLICABLE_SYNCS_SUCCESS and call fetchReplicableItems and toast', async () => {
      await testAction(
        actions.receiveInitiateAllReplicableSyncsSuccess,
        { action: ACTION_TYPES.RESYNC },
        state,
        [{ type: types.RECEIVE_INITIATE_ALL_REPLICABLE_SYNCS_SUCCESS }],
        [{ type: 'fetchReplicableItems' }],
        () => {
          expect(toast).toHaveBeenCalledTimes(1);
          toast.mockClear();
        },
      );
    });
  });

  describe('receiveInitiateAllReplicableSyncsError', () => {
    it('should commit mutation RECEIVE_INITIATE_ALL_REPLICABLE_SYNCS_ERROR', () => {
      testAction(
        actions.receiveInitiateAllReplicableSyncsError,
        ACTION_TYPES.RESYNC,
        state,
        [{ type: types.RECEIVE_INITIATE_ALL_REPLICABLE_SYNCS_ERROR }],
        [],
        () => {
          expect(createAlert).toHaveBeenCalledTimes(1);
        },
      );
    });
  });

  describe('initiateAllReplicableSyncs', () => {
    let action;

    describe('on success', () => {
      beforeEach(() => {
        action = ACTION_TYPES.RESYNC;
        jest
          .spyOn(Api, 'initiateAllGeoReplicableSyncs')
          .mockResolvedValue(MOCK_BASIC_POST_RESPONSE);
      });

      it('should dispatch the request with correct replicable param and success actions', () => {
        testAction(
          actions.initiateAllReplicableSyncs,
          action,
          state,
          [],
          [
            { type: 'requestInitiateAllReplicableSyncs' },
            { type: 'receiveInitiateAllReplicableSyncsSuccess', payload: { action } },
          ],
          () => {
            expect(Api.initiateAllGeoReplicableSyncs).toHaveBeenCalledWith(
              MOCK_REPLICABLE_TYPE,
              action,
            );
          },
        );
      });
    });

    describe('on error', () => {
      beforeEach(() => {
        action = ACTION_TYPES.RESYNC;
        jest
          .spyOn(Api, 'initiateAllGeoReplicableSyncs')
          .mockRejectedValue(new Error(HTTP_STATUS_INTERNAL_SERVER_ERROR));
      });

      it('should dispatch the request and error actions', async () => {
        await testAction(
          actions.initiateAllReplicableSyncs,
          action,
          state,
          [],
          [
            { type: 'requestInitiateAllReplicableSyncs' },
            { type: 'receiveInitiateAllReplicableSyncsError' },
          ],
        );
      });
    });
  });

  describe('requestInitiateReplicableSync', () => {
    it('should commit mutation REQUEST_INITIATE_REPLICABLE_SYNC', async () => {
      await testAction(
        actions.requestInitiateReplicableSync,
        null,
        state,
        [{ type: types.REQUEST_INITIATE_REPLICABLE_SYNC }],
        [],
      );
    });
  });

  describe('receiveInitiateReplicableSyncSuccess', () => {
    it('should commit mutation RECEIVE_INITIATE_REPLICABLE_SYNC_SUCCESS and call fetchReplicableItems and toast', async () => {
      await testAction(
        actions.receiveInitiateReplicableSyncSuccess,
        { action: ACTION_TYPES.RESYNC, projectName: 'test' },
        state,
        [{ type: types.RECEIVE_INITIATE_REPLICABLE_SYNC_SUCCESS }],
        [{ type: 'fetchReplicableItems' }],
      );
      expect(toast).toHaveBeenCalledTimes(1);
      toast.mockClear();
    });
  });

  describe('receiveInitiateReplicableSyncError', () => {
    it('should commit mutation RECEIVE_INITIATE_REPLICABLE_SYNC_ERROR', async () => {
      await testAction(
        actions.receiveInitiateReplicableSyncError,
        { action: ACTION_TYPES.RESYNC, projectId: 1, projectName: 'test' },
        state,
        [{ type: types.RECEIVE_INITIATE_REPLICABLE_SYNC_ERROR }],
        [],
      );
      expect(createAlert).toHaveBeenCalledTimes(1);
    });
  });

  describe('initiateReplicableSync', () => {
    let action;
    let projectId;
    let name;

    describe('on success', () => {
      beforeEach(() => {
        action = ACTION_TYPES.RESYNC;
        projectId = 1;
        name = 'test';
        jest.spyOn(Api, 'initiateGeoReplicableSync').mockResolvedValue(MOCK_BASIC_POST_RESPONSE);
      });

      it('should dispatch the request with correct replicable param and success actions', () => {
        testAction(
          actions.initiateReplicableSync,
          { projectId, name, action },
          state,
          [],
          [
            { type: 'requestInitiateReplicableSync' },
            { type: 'receiveInitiateReplicableSyncSuccess', payload: { name, action } },
          ],
        );
        expect(Api.initiateGeoReplicableSync).toHaveBeenCalledWith(MOCK_REPLICABLE_TYPE, {
          projectId,
          action,
        });
      });
    });

    describe('on error', () => {
      beforeEach(() => {
        action = ACTION_TYPES.RESYNC;
        projectId = 1;
        name = 'test';
        jest
          .spyOn(Api, 'initiateGeoReplicableSync')
          .mockRejectedValue(new Error(HTTP_STATUS_INTERNAL_SERVER_ERROR));
      });

      it('should dispatch the request and error actions', async () => {
        await testAction(
          actions.initiateReplicableSync,
          { projectId, name, action },
          state,
          [],
          [
            { type: 'requestInitiateReplicableSync' },
            {
              type: 'receiveInitiateReplicableSyncError',
              payload: { name: 'test' },
            },
          ],
        );
      });
    });
  });

  describe('setFilter', () => {
    it('should commit mutation SET_FILTER', async () => {
      const testValue = 1;

      await testAction(
        actions.setFilter,
        testValue,
        state,
        [{ type: types.SET_FILTER, payload: testValue }],
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

  describe('setPage', () => {
    it('should commit mutation SET_PAGE', async () => {
      state.paginationData.page = 1;

      const testValue = 2;

      await testAction(
        actions.setPage,
        testValue,
        state,
        [{ type: types.SET_PAGE, payload: testValue }],
        [],
      );
    });
  });
});
