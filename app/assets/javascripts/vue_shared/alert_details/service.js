import {
  fetchAlertMetricImages,
  uploadAlertMetricImage,
  updateAlertMetricImage,
  deleteAlertMetricImage,
} from '~/rest_api';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

export const getMetricImages = async (payload) => {
  payload = replaceModelIId(payload);
  const response = await fetchAlertMetricImages(payload);
  return convertObjectPropsToCamelCase(response.data, { deep: true });
};

export const uploadMetricImage = async (payload) => {
  payload = replaceModelIId(payload);
  const response = await uploadAlertMetricImage(payload);
  return convertObjectPropsToCamelCase(response.data);
};

export const updateMetricImage = async (payload) => {
  payload = replaceModelIId(payload);
  const response = await updateAlertMetricImage(payload);
  return convertObjectPropsToCamelCase(response.data);
};

export const deleteMetricImage = async (payload) => {
  payload = replaceModelIId(payload);
  const response = await deleteAlertMetricImage(payload);
  return convertObjectPropsToCamelCase(response.data);
};

function replaceModelIId(payload) {
  delete Object.assign(payload, { alertIid: payload.modelIid }).modelIid;
  return payload;
}

export default {
  getMetricImages,
  uploadMetricImage,
  updateMetricImage,
  deleteMetricImage,
};
