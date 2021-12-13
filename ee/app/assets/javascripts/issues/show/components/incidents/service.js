import Api from 'ee/api';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

export const getMetricImages = async (payload) => {
  const response = await Api.fetchIssueMetricImages(payload);
  return convertObjectPropsToCamelCase(response.data, { deep: true });
};

export const uploadMetricImage = async (payload) => {
  const response = await Api.uploadIssueMetricImage(payload);
  return convertObjectPropsToCamelCase(response.data);
};

export const deleteMetricImage = async (payload) => {
  const response = await Api.deleteMetricImage(payload);
  return convertObjectPropsToCamelCase(response.data);
};
