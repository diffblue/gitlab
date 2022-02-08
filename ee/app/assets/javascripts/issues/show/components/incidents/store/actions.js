import createFlash from '~/flash';
import { s__ } from '~/locale';
import {
  deleteMetricImage,
  getMetricImages,
  uploadMetricImage,
  updateMetricImage,
} from '../service';
import * as types from './mutation_types';

export const fetchMetricImages = async ({ state, commit }) => {
  commit(types.REQUEST_METRIC_IMAGES);

  const { issueIid, projectId } = state;

  try {
    const response = await getMetricImages({ id: projectId, issueIid });
    commit(types.RECEIVE_METRIC_IMAGES_SUCCESS, response);
  } catch (error) {
    commit(types.RECEIVE_METRIC_IMAGES_ERROR);
    createFlash({ message: s__('Incidents|There was an issue loading metric images.') });
  }
};

export const uploadImage = async ({ state, commit }, { files, url, urlText }) => {
  commit(types.REQUEST_METRIC_UPLOAD);

  const { issueIid, projectId } = state;

  try {
    const response = await uploadMetricImage({
      file: files.item(0),
      id: projectId,
      issueIid,
      url,
      urlText,
    });
    commit(types.RECEIVE_METRIC_UPLOAD_SUCCESS, response);
  } catch (error) {
    commit(types.RECEIVE_METRIC_UPLOAD_ERROR);
    createFlash({ message: s__('Incidents|There was an issue uploading your image.') });
  }
};

export const updateImage = async ({ state, commit }, { imageId, url, urlText }) => {
  commit(types.REQUEST_METRIC_UPLOAD);

  const { issueIid, projectId } = state;

  try {
    const response = await updateMetricImage({
      issueIid,
      id: projectId,
      imageId,
      url,
      urlText,
    });
    commit(types.RECEIVE_METRIC_UPDATE_SUCCESS, response);
  } catch (error) {
    commit(types.RECEIVE_METRIC_UPLOAD_ERROR);
    createFlash({ message: s__('Incidents|There was an issue updating your image.') });
  }
};

export const deleteImage = async ({ state, commit }, imageId) => {
  const { issueIid, projectId } = state;

  try {
    await deleteMetricImage({ imageId, id: projectId, issueIid });
    commit(types.RECEIVE_METRIC_DELETE_SUCCESS, imageId);
  } catch (error) {
    createFlash({ message: s__('Incidents|There was an issue deleting the image.') });
  }
};

export const setInitialData = ({ commit }, data) => {
  commit(types.SET_INITIAL_DATA, data);
};
