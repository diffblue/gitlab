import Api from 'ee/api';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

function replaceModelIId(payload = {}) {
  const { modelIid, ...rest } = payload;
  return { issueIid: modelIid, ...rest };
}

export const getMetricImages = async (payload) => {
  const apiPayload = replaceModelIId(payload);
  const response = await Api.fetchIssueMetricImages(apiPayload);
  return convertObjectPropsToCamelCase(response.data, { deep: true });
};
export const uploadMetricImage = async (payload) => {
  const apiPayload = replaceModelIId(payload);
  const response = await Api.uploadIssueMetricImage(apiPayload);
  return convertObjectPropsToCamelCase(response.data);
};
export const updateMetricImage = async (payload) => {
  const apiPayload = replaceModelIId(payload);
  const response = await Api.updateIssueMetricImage(apiPayload);
  return convertObjectPropsToCamelCase(response.data);
};
export const deleteMetricImage = async (payload) => {
  const apiPayload = replaceModelIId(payload);
  const response = await Api.deleteMetricImage(apiPayload);
  return convertObjectPropsToCamelCase(response.data);
};

export default {
  getMetricImages,
  uploadMetricImage,
  updateMetricImage,
  deleteMetricImage,
};
