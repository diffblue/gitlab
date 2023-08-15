import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import FeatureFlagActions from 'ee/feature_flags/components/actions.vue';
import waitForPromises from 'helpers/wait_for_promises';
import { TEST_HOST } from 'spec/test_constants';
import EditFeatureFlag from '~/feature_flags/components/edit_feature_flag.vue';
import createStore from '~/feature_flags/store/edit';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';

Vue.use(Vuex);

const endpoint = `${TEST_HOST}/feature_flags.json`;

describe('Edit feature flag form', () => {
  let wrapper;
  let mock;

  const store = createStore({
    path: '/feature_flags',
    endpoint,
  });

  const factory = (provide = { searchPath: '/search' }) => {
    wrapper = shallowMount(EditFeatureFlag, {
      store,
      provide,
    });
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
    mock.onGet(endpoint).replyOnce(HTTP_STATUS_OK, {
      id: 21,
      iid: 5,
      active: true,
      created_at: '2019-01-17T17:27:39.778Z',
      updated_at: '2019-01-17T17:27:39.778Z',
      name: 'feature_flag',
      description: '',
      edit_path: '/h5bp/html5-boilerplate/-/feature_flags/21/edit',
      destroy_path: '/h5bp/html5-boilerplate/-/feature_flags/21',
    });
    factory();

    return waitForPromises();
  });

  afterEach(() => {
    mock.restore();
  });

  describe('without error', () => {
    it('shows a dropdown to search for code references', () => {
      expect(wrapper.findComponent(FeatureFlagActions).exists()).toBe(true);
    });
  });
});
