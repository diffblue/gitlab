import Vue from 'vue';
import Vuex from 'vuex';
import {
  getMetricImages,
  uploadMetricImage,
  updateMetricImage,
  deleteMetricImage,
} from 'ee/issues/show/components/incidents/service';
import createStore from 'ee/issues/show/components/incidents/store';
import * as actions from 'ee/issues/show/components/incidents/store/actions';
import * as types from 'ee/issues/show/components/incidents/store/mutation_types';
import testAction from 'helpers/vuex_action_helper';
import createFlash from '~/flash';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { fileList, initialData } from '../mock_data';

jest.mock('~/flash');
jest.mock('ee/issues/show/components/incidents/service', () => ({
  getMetricImages: jest.fn(),
  uploadMetricImage: jest.fn(),
  updateMetricImage: jest.fn(),
  deleteMetricImage: jest.fn(),
}));

const defaultState = {
  issueIid: 1,
  projectId: '2',
};

Vue.use(Vuex);

describe('Metrics tab store actions', () => {
  let store;
  let state;

  beforeEach(() => {
    store = createStore(defaultState);
    state = store.state;
  });

  afterEach(() => {
    createFlash.mockClear();
  });

  describe('fetching metric images', () => {
    it('should call success action when fetching metric images', () => {
      getMetricImages.mockImplementation(() => Promise.resolve(fileList));

      testAction(actions.fetchMetricImages, null, state, [
        { type: types.REQUEST_METRIC_IMAGES },
        {
          type: types.RECEIVE_METRIC_IMAGES_SUCCESS,
          payload: convertObjectPropsToCamelCase(fileList, { deep: true }),
        },
      ]);
    });

    it('should call error action when fetching metric images with an error', async () => {
      getMetricImages.mockImplementation(() => Promise.reject());

      await testAction(
        actions.fetchMetricImages,
        null,
        state,
        [{ type: types.REQUEST_METRIC_IMAGES }, { type: types.RECEIVE_METRIC_IMAGES_ERROR }],
        [],
      );
      expect(createFlash).toHaveBeenCalled();
    });
  });

  describe('uploading metric images', () => {
    const payload = {
      // mock the FileList api
      files: {
        item() {
          return fileList[0];
        },
      },
      url: 'test_url',
    };

    it('should call success action when uploading an image', () => {
      uploadMetricImage.mockImplementation(() => Promise.resolve(fileList[0]));

      testAction(actions.uploadImage, payload, state, [
        { type: types.REQUEST_METRIC_UPLOAD },
        {
          type: types.RECEIVE_METRIC_UPLOAD_SUCCESS,
          payload: fileList[0],
        },
      ]);
    });

    it('should call error action when failing to upload an image', async () => {
      uploadMetricImage.mockImplementation(() => Promise.reject());

      await testAction(
        actions.uploadImage,
        payload,
        state,
        [{ type: types.REQUEST_METRIC_UPLOAD }, { type: types.RECEIVE_METRIC_UPLOAD_ERROR }],
        [],
      );
      expect(createFlash).toHaveBeenCalled();
    });
  });

  describe('updating metric images', () => {
    const payload = {
      url: 'test_url',
      urlText: 'url text',
    };

    it('should call success action when updating an image', () => {
      updateMetricImage.mockImplementation(() => Promise.resolve());

      testAction(actions.updateImage, payload, state, [
        { type: types.REQUEST_METRIC_UPLOAD },
        {
          type: types.RECEIVE_METRIC_UPDATE_SUCCESS,
        },
      ]);
    });

    it('should call error action when failing to update an image', async () => {
      updateMetricImage.mockImplementation(() => Promise.reject());

      await testAction(
        actions.updateImage,
        payload,
        state,
        [{ type: types.REQUEST_METRIC_UPLOAD }, { type: types.RECEIVE_METRIC_UPLOAD_ERROR }],
        [],
      );
      expect(createFlash).toHaveBeenCalled();
    });
  });

  describe('deleting a metric image', () => {
    const payload = fileList[0].id;

    it('should call success action when deleting an image', () => {
      deleteMetricImage.mockImplementation(() => Promise.resolve());

      testAction(actions.deleteImage, payload, state, [
        {
          type: types.RECEIVE_METRIC_DELETE_SUCCESS,
          payload,
        },
      ]);
    });
  });

  describe('initial data', () => {
    it('should set the initial data correctly', () => {
      testAction(actions.setInitialData, initialData, state, [
        { type: types.SET_INITIAL_DATA, payload: initialData },
      ]);
    });
  });
});
