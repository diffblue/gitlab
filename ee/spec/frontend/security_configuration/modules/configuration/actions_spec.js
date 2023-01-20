import MockAdapter from 'axios-mock-adapter';
import * as actions from 'ee/security_configuration/modules/configuration/actions';
import * as types from 'ee/security_configuration/modules/configuration/mutation_types';
import createState from 'ee/security_configuration/modules/configuration/state';
import testAction from 'helpers/vuex_action_helper';
import { TEST_HOST } from 'spec/test_constants';

import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_NOT_FOUND } from '~/lib/utils/http_status';

describe('security configuration module actions', () => {
  let state;

  beforeEach(() => {
    state = createState({
      securityConfigurationPath: `${TEST_HOST}/-/security/configuration.json`,
    });
  });

  describe('fetchSecurityConfiguration', () => {
    let mock;
    const configuration = {};

    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('on success', () => {
      beforeEach(() => {
        mock.onGet(state.securityConfigurationPath).replyOnce(200, configuration);
      });

      it('should commit the request and success mutations', async () => {
        await testAction(
          actions.fetchSecurityConfiguration,
          {},
          state,
          [
            { type: types.REQUEST_SECURITY_CONFIGURATION },
            {
              type: types.RECEIVE_SECURITY_CONFIGURATION_SUCCESS,
              payload: configuration,
            },
          ],
          [],
        );
      });
    });

    describe('without securityConfigurationPath set', () => {
      beforeEach(() => {
        mock.onGet(state.securityConfigurationPath).replyOnce(200, configuration);
      });

      it('should commit RECEIVE_SECURITY_CONFIGURATION_ERROR mutation', async () => {
        state.securityConfigurationPath = '';

        await testAction(
          actions.fetchSecurityConfiguration,
          {},
          state,
          [
            {
              type: types.RECEIVE_SECURITY_CONFIGURATION_ERROR,
            },
          ],
          [],
        );
      });
    });

    describe('with server error', () => {
      beforeEach(() => {
        mock.onGet(state.securityConfigurationPath).replyOnce(HTTP_STATUS_NOT_FOUND);
      });

      it('should commit REQUEST_SECURITY_CONFIGURATION and RECEIVE_SECURITY_CONFIGURATION_ERRORmutation', async () => {
        await testAction(
          actions.fetchSecurityConfiguration,
          {},
          state,
          [
            { type: types.REQUEST_SECURITY_CONFIGURATION },
            {
              type: types.RECEIVE_SECURITY_CONFIGURATION_ERROR,
            },
          ],
          [],
        );
      });
    });
  });
});
