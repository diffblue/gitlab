import MockAdapter from 'axios-mock-adapter';
import * as actions from 'ee/geo_sites/store/actions';
import * as types from 'ee/geo_sites/store/mutation_types';
import createState from 'ee/geo_sites/store/state';
import testAction from 'helpers/vuex_action_helper';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import {
  MOCK_REPLICABLE_TYPES,
  MOCK_SITES,
  MOCK_SITES_RES,
  MOCK_SITE_STATUSES_RES,
} from '../mock_data';

jest.mock('~/alert');

describe('GeoSites Store Actions', () => {
  let mock;
  let state;

  beforeEach(() => {
    state = createState({
      replicableTypes: MOCK_REPLICABLE_TYPES,
    });
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    state = null;
    mock.restore();
  });

  describe('fetchSites', () => {
    describe('on success', () => {
      beforeEach(() => {
        // geo_nodes API to be renamed geo_sites API => https://gitlab.com/gitlab-org/gitlab/-/issues/369140
        mock.onGet(/api\/(.*)\/geo_nodes/).replyOnce(HTTP_STATUS_OK, MOCK_SITES_RES);
        mock
          .onGet(/api\/(.*)\/geo_nodes\/status/)
          .replyOnce(HTTP_STATUS_OK, MOCK_SITE_STATUSES_RES);
      });

      it('should dispatch the correct mutations', () => {
        return testAction({
          action: actions.fetchSites,
          payload: null,
          state,
          expectedMutations: [
            { type: types.REQUEST_SITES },
            { type: types.RECEIVE_SITES_SUCCESS, payload: MOCK_SITES },
          ],
        });
      });
    });

    describe('on error', () => {
      beforeEach(() => {
        // geo_nodes API to be renamed geo_sites API => https://gitlab.com/gitlab-org/gitlab/-/issues/369140
        mock.onGet(/api\/(.*)\/geo_nodes/).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
        mock.onGet(/api\/(.*)\/geo_nodes\/status/).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
      });

      it('should dispatch the correct mutations', () => {
        return testAction({
          action: actions.fetchSites,
          payload: null,
          state,
          expectedMutations: [{ type: types.REQUEST_SITES }, { type: types.RECEIVE_SITES_ERROR }],
        }).then(() => {
          expect(createAlert).toHaveBeenCalledTimes(1);
          createAlert.mockClear();
        });
      });
    });
  });

  describe('removeSite', () => {
    describe('on success', () => {
      beforeEach(() => {
        // geo_nodes API to be renamed geo_sites API => https://gitlab.com/gitlab-org/gitlab/-/issues/369140
        mock.onDelete(/api\/.*\/geo_nodes/).replyOnce(HTTP_STATUS_OK, {});
      });

      it('should dispatch the correct mutations', () => {
        return testAction({
          action: actions.removeSite,
          payload: null,
          state,
          expectedMutations: [
            { type: types.REQUEST_SITE_REMOVAL },
            { type: types.RECEIVE_SITE_REMOVAL_SUCCESS },
          ],
        });
      });
    });

    describe('on error', () => {
      beforeEach(() => {
        // geo_nodes API to be renamed geo_sites API => https://gitlab.com/gitlab-org/gitlab/-/issues/369140
        mock.onDelete(/api\/(.*)\/geo_nodes/).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
      });

      it('should dispatch the correct mutations', () => {
        return testAction({
          action: actions.removeSite,
          payload: null,
          state,
          expectedMutations: [
            { type: types.REQUEST_SITE_REMOVAL },
            { type: types.RECEIVE_SITE_REMOVAL_ERROR },
          ],
        }).then(() => {
          expect(createAlert).toHaveBeenCalledTimes(1);
          createAlert.mockClear();
        });
      });
    });
  });

  describe('prepSiteRemoval', () => {
    it('should dispatch the correct mutations', () => {
      return testAction({
        action: actions.prepSiteRemoval,
        payload: 1,
        state,
        expectedMutations: [{ type: types.STAGE_SITE_REMOVAL, payload: 1 }],
      });
    });
  });

  describe('cancelSiteRemoval', () => {
    it('should dispatch the correct mutations', () => {
      return testAction({
        action: actions.cancelSiteRemoval,
        payload: null,
        state,
        expectedMutations: [{ type: types.UNSTAGE_SITE_REMOVAL }],
      });
    });
  });

  describe('setStatusFilter', () => {
    it('should dispatch the correct mutations', () => {
      return testAction({
        action: actions.setStatusFilter,
        payload: 'healthy',
        state,
        expectedMutations: [{ type: types.SET_STATUS_FILTER, payload: 'healthy' }],
      });
    });
  });

  describe('setSearchFilter', () => {
    it('should dispatch the correct mutations', () => {
      return testAction({
        action: actions.setSearchFilter,
        payload: 'search',
        state,
        expectedMutations: [{ type: types.SET_SEARCH_FILTER, payload: 'search' }],
      });
    });
  });
});
