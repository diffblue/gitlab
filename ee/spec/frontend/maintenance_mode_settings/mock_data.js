import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import * as types from 'ee/maintenance_mode_settings/store/mutation_types';

export const MOCK_APPLICATION_SETTINGS_UPDATE_RESPONSE = {
  maintenance_mode: true,
  maintenance_mode_message: 'Test Message',
};

export const MOCK_BASIC_SETTINGS_DATA = {
  maintenanceEnabled: MOCK_APPLICATION_SETTINGS_UPDATE_RESPONSE.maintenance_mode,
  bannerMessage: MOCK_APPLICATION_SETTINGS_UPDATE_RESPONSE.maintenance_mode_message,
};

export const ACTIONS_TEST_DATA = {
  setMaintenanceEnabledData: { maintenanceEnabled: MOCK_BASIC_SETTINGS_DATA.maintenanceEnabled },
  setMaintenanceEnabledMutations: {
    type: types.SET_MAINTENANCE_ENABLED,
    payload: MOCK_BASIC_SETTINGS_DATA.maintenanceEnabled,
  },
  setBannerMessageData: { bannerMessage: MOCK_BASIC_SETTINGS_DATA.bannerMessage },
  setBannerMessageMutations: {
    type: types.SET_BANNER_MESSAGE,
    payload: MOCK_BASIC_SETTINGS_DATA.bannerMessage,
  },
  successfulAxiosCall: {
    method: 'onPut',
    code: HTTP_STATUS_OK,
    res: MOCK_APPLICATION_SETTINGS_UPDATE_RESPONSE,
  },
  updateSuccessMutations: [
    { type: types.REQUEST_UPDATE_MAINTENANCE_MODE_SETTINGS },
    {
      type: types.RECEIVE_UPDATE_MAINTENANCE_MODE_SETTINGS_SUCCESS,
      payload: MOCK_BASIC_SETTINGS_DATA,
    },
  ],
  errorAxiosCall: { method: 'onPut', code: HTTP_STATUS_INTERNAL_SERVER_ERROR, res: null },
  updateErrorMutations: [
    { type: types.REQUEST_UPDATE_MAINTENANCE_MODE_SETTINGS },
    { type: types.RECEIVE_UPDATE_MAINTENANCE_MODE_SETTINGS_ERROR },
  ],
};
