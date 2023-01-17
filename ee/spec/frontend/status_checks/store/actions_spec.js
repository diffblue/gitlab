import MockAdapter from 'axios-mock-adapter';
import * as actions from 'ee/status_checks/store/actions';
import * as types from 'ee/status_checks/store/mutation_types';
import axios from '~/lib/utils/axios_utils';
import { convertObjectPropsToSnakeCase } from '~/lib/utils/common_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';

const statusChecksPath = '/api/v4/projects/1/external_status_checks';
const rootState = { settings: { statusChecksPath } };
const commit = jest.fn();
const dispatch = jest.fn();
let mockAxios;

describe('Status checks actions', () => {
  beforeEach(() => {
    mockAxios = new MockAdapter(axios);
  });

  afterEach(() => {
    mockAxios.restore();
  });

  describe('setSettings', () => {
    it('should commit the settings', () => {
      const settings = { projectId: '12345', statusChecksPath };

      actions.setSettings({ commit }, settings);

      expect(commit).toHaveBeenCalledWith(types.SET_SETTINGS, settings);
    });
  });

  describe('fetchStatusChecks', () => {
    it(`should commit the API response`, async () => {
      const data = [{ name: 'Foo' }, { name: 'Bar' }];

      mockAxios.onGet(statusChecksPath).replyOnce(HTTP_STATUS_OK, data);

      await actions.fetchStatusChecks({ commit, rootState });

      expect(commit).toHaveBeenCalledWith(types.SET_LOADING, true);
      expect(commit).toHaveBeenCalledWith(types.SET_STATUS_CHECKS, data);
      expect(commit).toHaveBeenCalledWith(types.SET_LOADING, false);
    });

    it('should error with a failed API response', async () => {
      mockAxios.onGet(statusChecksPath).networkError();

      await expect(actions.fetchStatusChecks({ commit, rootState })).rejects.toThrow(
        new Error('Network Error'),
      );
      expect(commit).toHaveBeenCalledWith(types.SET_LOADING, true);
      expect(commit).toHaveBeenCalledTimes(1);
    });
  });

  describe('when creating and updating a status check', () => {
    const defaultData = {
      name: 'Foo',
      externalUrl: 'https://bar.com',
      protectedBranchIds: [1],
    };

    it.each`
      action               | axiosMethod | httpMethod | statusCheck                  | url
      ${'postStatusCheck'} | ${'onPost'} | ${'post'}  | ${defaultData}               | ${statusChecksPath}
      ${'putStatusCheck'}  | ${'onPut'}  | ${'put'}   | ${{ ...defaultData, id: 1 }} | ${`${statusChecksPath}/1`}
    `(
      'should $httpMethod to the API and then dispatch fetchStatusChecks',
      async ({ action, axiosMethod, httpMethod, statusCheck, url }) => {
        mockAxios[axiosMethod](url).replyOnce(HTTP_STATUS_OK);

        await actions[action]({ dispatch, rootState }, statusCheck);

        expect(JSON.parse(mockAxios.history[httpMethod][0].data)).toStrictEqual(
          convertObjectPropsToSnakeCase(statusCheck, { deep: true }),
        );
        expect(dispatch).toHaveBeenCalledWith('fetchStatusChecks');
      },
    );
  });

  describe('deleteStatusCheck', () => {
    it(`should DELETE call the API and then dispatch a new fetchStatusChecks`, async () => {
      const id = 1;

      mockAxios.onPost(statusChecksPath).replyOnce(HTTP_STATUS_OK);

      await actions.postStatusCheck({ dispatch, rootState }, id);

      expect(dispatch).toHaveBeenCalledWith('fetchStatusChecks');
    });
  });
});
