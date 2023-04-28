import Visibility from 'visibilityjs';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_BAD_REQUEST, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import Poll from '~/lib/utils/poll';
import { __ } from '~/locale';
import { MAX_RETRIES, RETRY_DELAY } from './constants';

import * as types from './mutation_types';

export * from '~/diffs/store/actions';

let codequalityPoll;

export const setCodequalityEndpoint = ({ commit }, endpoint) => {
  commit(types.SET_CODEQUALITY_ENDPOINT, endpoint);
};

export const clearCodequalityPoll = () => {
  codequalityPoll = null;
};

export const stopCodequalityPolling = () => {
  if (codequalityPoll) codequalityPoll.stop();
};

export const restartCodequalityPolling = () => {
  if (codequalityPoll) codequalityPoll.restart();
};

export const fetchCodequality = ({ commit, state, dispatch }) => {
  let retryCount = 0;

  codequalityPoll = new Poll({
    resource: {
      getCodequalityDiffReports: (endpoint) => axios.get(endpoint),
    },
    data: state.endpointCodequality,
    method: 'getCodequalityDiffReports',
    successCallback: ({ status, data }) => {
      retryCount = 0;
      if (status === HTTP_STATUS_OK) {
        commit(types.SET_CODEQUALITY_DATA, data);

        dispatch('stopCodequalityPolling');
      }
    },
    errorCallback: ({ response }) => {
      if (response.status === HTTP_STATUS_BAD_REQUEST) {
        // we could get a 400 status response temporarily during report processing
        // so we retry up to MAX_RETRIES times in case the reports are on their way
        // and stop polling if we get 400s consistently
        if (retryCount < MAX_RETRIES) {
          codequalityPoll.makeDelayedRequest(RETRY_DELAY);
          retryCount += 1;
        } else {
          codequalityPoll.stop();
        }
      } else {
        retryCount = 0;
        dispatch('stopCodequalityPolling');
        createAlert({
          message: __('An unexpected error occurred while loading the code quality diff.'),
        });
      }
    },
  });

  if (!Visibility.hidden()) {
    codequalityPoll.makeRequest();
  }

  Visibility.change(() => {
    if (!Visibility.hidden()) {
      dispatch('restartCodequalityPolling');
    } else {
      dispatch('stopCodequalityPolling');
    }
  });
};

export const setGenerateTestFilePath = ({ commit }, path) =>
  commit(types.SET_GENERATE_TEST_FILE_PATH, path);
