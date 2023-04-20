import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { refreshCurrentPage } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import * as mutationTypes from './mutation_types';

export const setStatusPageEnabled = ({ commit }, { enabled }) =>
  commit(mutationTypes.SET_STATUS_PAGE_ENABLED, enabled);
export const setStatusPageUrl = ({ commit }, { url }) =>
  commit(mutationTypes.SET_STATUS_PAGE_URL, url);
export const setStatusPageBucketName = ({ commit }, { bucketName }) =>
  commit(mutationTypes.SET_BUCKET_NAME, bucketName);
export const setStatusPageRegion = ({ commit }, { region }) =>
  commit(mutationTypes.SET_REGION, region);
export const setStatusPageAccessKey = ({ commit }, { awsAccessKey }) =>
  commit(mutationTypes.SET_ACCESS_KEY_ID, awsAccessKey);
export const setStatusPageSecretAccessKey = ({ commit }, { awsSecretKey }) =>
  commit(mutationTypes.SET_SECRET_ACCESS_KEY, awsSecretKey);

export const updateStatusPageSettings = ({ state, dispatch, commit }) => {
  commit(mutationTypes.LOADING, true);

  axios
    .patch(state.operationsSettingsEndpoint, {
      project: {
        status_page_setting_attributes: {
          enabled: state.enabled,
          status_page_url: state.url,
          aws_s3_bucket_name: state.bucketName,
          aws_region: state.region,
          aws_access_key: state.awsAccessKey,
          aws_secret_key: state.awsSecretKey,
        },
      },
    })
    .then(() => dispatch('receiveStatusPageSettingsUpdateSuccess'))
    .catch((error) => dispatch('receiveStatusPageSettingsUpdateError', error))
    .finally(() => commit(mutationTypes.LOADING, false));
};

export const receiveStatusPageSettingsUpdateSuccess = () => {
  /**
   * The operations_controller currently handles successful requests
   * by creating an alert banner message to notify the user.
   */
  refreshCurrentPage();
};

export const receiveStatusPageSettingsUpdateError = (_, error) => {
  const { response } = error;
  const message = response?.data?.message || '';

  createAlert({
    message: `${__('There was an error saving your changes.')} ${message}`,
  });
};
