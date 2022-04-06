import Api from 'ee/api';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

function replaceModelIId(payload = {}) {
  const { modelIid, ...rest } = payload;
  return { issueIid: modelIid, ...rest };
}

export const getMetricImages = async (payload) => {
  payload = replaceModelIId(payload);
  const response = await Api.fetchIssueMetricImages(payload);
  return convertObjectPropsToCamelCase(response.data, { deep: true });
};
export const uploadMetricImage = async (payload) => {
  payload = replaceModelIId(payload);
  const response = await Api.uploadIssueMetricImage(payload);
  return convertObjectPropsToCamelCase(response.data);
};
export const updateMetricImage = async (payload) => {
  payload = replaceModelIId(payload);
  const response = await Api.updateIssueMetricImage(payload);
  return convertObjectPropsToCamelCase(response.data);
};
export const deleteMetricImage = async (payload) => {
  payload = replaceModelIId(payload);
  const response = await Api.deleteMetricImage(payload);
  return convertObjectPropsToCamelCase(response.data);
};

export default {
  getMetricImages,
  uploadMetricImage,
  updateMetricImage,
  deleteMetricImage,
};
