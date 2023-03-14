import MockAdapter from 'axios-mock-adapter';
import * as actions from 'ee/geo_site_form/store/actions';
import * as types from 'ee/geo_site_form/store/mutation_types';
import createState from 'ee/geo_site_form/store/state';
import testAction from 'helpers/vuex_action_helper';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { visitUrl } from '~/lib/utils/url_utility';
import { MOCK_SYNC_NAMESPACES, MOCK_SITE, MOCK_ERROR_MESSAGE, MOCK_SITES_PATH } from '../mock_data';

jest.mock('~/helpers/help_page_helper');
jest.mock('~/alert');
jest.mock('~/lib/utils/url_utility', () => ({
  visitUrl: jest.fn().mockName('visitUrlMock'),
  joinPaths: jest.fn(),
}));

describe('GeoSiteForm Store Actions', () => {
  let state;
  let mock;

  const noCallback = () => {};
  const alertCallback = () => {
    expect(createAlert).toHaveBeenCalledTimes(1);
    createAlert.mockClear();
  };
  const visitUrlCallback = () => {
    expect(visitUrl).toHaveBeenCalledWith(MOCK_SITES_PATH);
  };

  beforeEach(() => {
    state = createState(MOCK_SITES_PATH);
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe.each`
    action                                  | data                               | mutationName                             | mutationCall                                                                      | callback
    ${actions.requestSyncNamespaces}        | ${null}                            | ${types.REQUEST_SYNC_NAMESPACES}         | ${{ type: types.REQUEST_SYNC_NAMESPACES }}                                        | ${noCallback}
    ${actions.receiveSyncNamespacesSuccess} | ${MOCK_SYNC_NAMESPACES}            | ${types.RECEIVE_SYNC_NAMESPACES_SUCCESS} | ${{ type: types.RECEIVE_SYNC_NAMESPACES_SUCCESS, payload: MOCK_SYNC_NAMESPACES }} | ${noCallback}
    ${actions.receiveSyncNamespacesError}   | ${null}                            | ${types.RECEIVE_SYNC_NAMESPACES_ERROR}   | ${{ type: types.RECEIVE_SYNC_NAMESPACES_ERROR }}                                  | ${alertCallback}
    ${actions.requestSaveGeoSite}           | ${null}                            | ${types.REQUEST_SAVE_GEO_SITE}           | ${{ type: types.REQUEST_SAVE_GEO_SITE }}                                          | ${noCallback}
    ${actions.receiveSaveGeoSiteSuccess}    | ${null}                            | ${types.RECEIVE_SAVE_GEO_SITE_COMPLETE}  | ${{ type: types.RECEIVE_SAVE_GEO_SITE_COMPLETE }}                                 | ${visitUrlCallback}
    ${actions.receiveSaveGeoSiteError}      | ${{ message: MOCK_ERROR_MESSAGE }} | ${types.RECEIVE_SAVE_GEO_SITE_COMPLETE}  | ${{ type: types.RECEIVE_SAVE_GEO_SITE_COMPLETE }}                                 | ${alertCallback}
    ${actions.setError}                     | ${{ key: 'name', error: 'error' }} | ${types.SET_ERROR}                       | ${{ type: types.SET_ERROR, payload: { key: 'name', error: 'error' } }}            | ${noCallback}
  `(`non-axios calls`, ({ action, data, mutationName, mutationCall, callback }) => {
    describe(action.name, () => {
      it(`should commit mutation ${mutationName}`, () => {
        return testAction(action, data, state, [mutationCall], []).then(() => callback());
      });
    });
  });

  describe.each`
    action                         | axiosMock                                                                                              | data                          | type         | actionCalls
    ${actions.fetchSyncNamespaces} | ${{ method: 'onGet', code: HTTP_STATUS_OK, res: MOCK_SYNC_NAMESPACES }}                                | ${null}                       | ${'success'} | ${[{ type: 'requestSyncNamespaces' }, { type: 'receiveSyncNamespacesSuccess', payload: MOCK_SYNC_NAMESPACES }]}
    ${actions.fetchSyncNamespaces} | ${{ method: 'onGet', code: HTTP_STATUS_INTERNAL_SERVER_ERROR, res: null }}                             | ${null}                       | ${'error'}   | ${[{ type: 'requestSyncNamespaces' }, { type: 'receiveSyncNamespacesError' }]}
    ${actions.saveGeoSite}         | ${{ method: 'onPost', code: HTTP_STATUS_OK, res: { ...MOCK_SITE, id: null } }}                         | ${{ ...MOCK_SITE, id: null }} | ${'success'} | ${[{ type: 'requestSaveGeoSite' }, { type: 'receiveSaveGeoSiteSuccess' }]}
    ${actions.saveGeoSite}         | ${{ method: 'onPost', code: HTTP_STATUS_INTERNAL_SERVER_ERROR, res: { message: MOCK_ERROR_MESSAGE } }} | ${{ ...MOCK_SITE, id: null }} | ${'error'}   | ${[{ type: 'requestSaveGeoSite' }, { type: 'receiveSaveGeoSiteError', payload: { message: MOCK_ERROR_MESSAGE } }]}
    ${actions.saveGeoSite}         | ${{ method: 'onPut', code: HTTP_STATUS_OK, res: MOCK_SITE }}                                           | ${MOCK_SITE}                  | ${'success'} | ${[{ type: 'requestSaveGeoSite' }, { type: 'receiveSaveGeoSiteSuccess' }]}
    ${actions.saveGeoSite}         | ${{ method: 'onPut', code: HTTP_STATUS_INTERNAL_SERVER_ERROR, res: { message: MOCK_ERROR_MESSAGE } }}  | ${MOCK_SITE}                  | ${'error'}   | ${[{ type: 'requestSaveGeoSite' }, { type: 'receiveSaveGeoSiteError', payload: { message: MOCK_ERROR_MESSAGE } }]}
  `(`axios calls`, ({ action, axiosMock, data, type, actionCalls }) => {
    describe(action.name, () => {
      describe(`on ${type}`, () => {
        beforeEach(() => {
          mock[axiosMock.method]().replyOnce(axiosMock.code, axiosMock.res);
        });
        it(`should dispatch the correct request and actions`, () => {
          return testAction(action, data, state, [], actionCalls);
        });
      });
    });
  });

  describe('receiveSaveGeoSiteError', () => {
    const defaultErrorMessage = 'There was an error saving this Geo Site';

    it('when message passed it builds the error message correctly', () => {
      return testAction(
        actions.receiveSaveGeoSiteError,
        { message: MOCK_ERROR_MESSAGE },
        state,
        [{ type: types.RECEIVE_SAVE_GEO_SITE_COMPLETE }],
        [],
      ).then(() => {
        const errors = "Errors: name can't be blank, url can't be blank, url must be a valid URL";
        expect(createAlert).toHaveBeenCalledWith({
          message: `${defaultErrorMessage} ${errors}`,
        });
        createAlert.mockClear();
      });
    });

    it('when no data is passed it defaults the error message', () => {
      return testAction(
        actions.receiveSaveGeoSiteError,
        null,
        state,
        [{ type: types.RECEIVE_SAVE_GEO_SITE_COMPLETE }],
        [],
      ).then(() => {
        expect(createAlert).toHaveBeenCalledWith({
          message: defaultErrorMessage,
        });
        createAlert.mockClear();
      });
    });
  });
});
