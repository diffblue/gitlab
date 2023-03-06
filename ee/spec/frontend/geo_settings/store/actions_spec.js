import MockAdapter from 'axios-mock-adapter';
import * as actions from 'ee/geo_settings/store/actions';
import * as types from 'ee/geo_settings/store/mutation_types';
import state from 'ee/geo_settings/store/state';
import testAction from 'helpers/vuex_action_helper';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { MOCK_BASIC_SETTINGS_DATA, MOCK_APPLICATION_SETTINGS_FETCH_RESPONSE } from '../mock_data';

jest.mock('~/alert');

describe('GeoSettings Store Actions', () => {
  let mock;

  const noCallback = () => {};
  const alertCallback = () => {
    expect(createAlert).toHaveBeenCalledTimes(1);
    createAlert.mockClear();
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe.each`
    action                  | data                                                 | mutationName            | mutationCall                                                                   | callback
    ${actions.setTimeout}   | ${{ timeout: MOCK_BASIC_SETTINGS_DATA.timeout }}     | ${types.SET_TIMEOUT}    | ${{ type: types.SET_TIMEOUT, payload: MOCK_BASIC_SETTINGS_DATA.timeout }}      | ${noCallback}
    ${actions.setAllowedIp} | ${{ allowedIp: MOCK_BASIC_SETTINGS_DATA.allowedIp }} | ${types.SET_ALLOWED_IP} | ${{ type: types.SET_ALLOWED_IP, payload: MOCK_BASIC_SETTINGS_DATA.allowedIp }} | ${noCallback}
    ${actions.setFormError} | ${{ key: 'timeout', error: 'error' }}                | ${types.SET_FORM_ERROR} | ${{ type: types.SET_FORM_ERROR, payload: { key: 'timeout', error: 'error' } }} | ${noCallback}
  `(`non-axios calls`, ({ action, data, mutationName, mutationCall, callback }) => {
    describe(action.name, () => {
      it(`should commit mutation ${mutationName}`, () => {
        return testAction(action, data, state, [mutationCall], []).then(() => callback());
      });
    });
  });

  describe.each`
    action                       | axiosMock                                                                                   | type         | mutationCalls                                                                                                                            | callback
    ${actions.fetchGeoSettings}  | ${{ method: 'onGet', code: HTTP_STATUS_OK, res: MOCK_APPLICATION_SETTINGS_FETCH_RESPONSE }} | ${'success'} | ${[{ type: types.REQUEST_GEO_SETTINGS }, { type: types.RECEIVE_GEO_SETTINGS_SUCCESS, payload: MOCK_BASIC_SETTINGS_DATA }]}               | ${noCallback}
    ${actions.fetchGeoSettings}  | ${{ method: 'onGet', code: HTTP_STATUS_INTERNAL_SERVER_ERROR, res: null }}                  | ${'error'}   | ${[{ type: types.REQUEST_GEO_SETTINGS }, { type: types.RECEIVE_GEO_SETTINGS_ERROR }]}                                                    | ${alertCallback}
    ${actions.updateGeoSettings} | ${{ method: 'onPut', code: HTTP_STATUS_OK, res: MOCK_APPLICATION_SETTINGS_FETCH_RESPONSE }} | ${'success'} | ${[{ type: types.REQUEST_UPDATE_GEO_SETTINGS }, { type: types.RECEIVE_UPDATE_GEO_SETTINGS_SUCCESS, payload: MOCK_BASIC_SETTINGS_DATA }]} | ${noCallback}
    ${actions.updateGeoSettings} | ${{ method: 'onPut', code: HTTP_STATUS_INTERNAL_SERVER_ERROR, res: null }}                  | ${'error'}   | ${[{ type: types.REQUEST_UPDATE_GEO_SETTINGS }, { type: types.RECEIVE_UPDATE_GEO_SETTINGS_ERROR }]}                                      | ${alertCallback}
  `(`axios calls`, ({ action, axiosMock, type, mutationCalls, callback }) => {
    describe(action.name, () => {
      describe(`on ${type}`, () => {
        beforeEach(() => {
          mock[axiosMock.method]().replyOnce(axiosMock.code, axiosMock.res);
        });
        it(`should dispatch the correct mutations`, () => {
          return testAction(action, null, state, mutationCalls, []).then(() => callback());
        });
      });
    });
  });
});
