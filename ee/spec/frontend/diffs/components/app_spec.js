import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';

import Vue from 'vue';
import Vuex from 'vuex';
import { stubPerformanceWebAPI } from 'helpers/performance';
import createDiffsStore from 'jest/diffs/create_diffs_store';
import { TEST_HOST } from 'spec/test_constants';
import App from '~/diffs/components/app.vue';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';

const TEST_ENDPOINT = `${TEST_HOST}/diff/endpoint`;

Vue.use(Vuex);

Vue.config.ignoredElements = ['copy-code'];

describe('diffs/components/app', () => {
  let store;
  let wrapper;
  let mock;

  function createComponent(props = {}, extendStore = () => {}) {
    store = createDiffsStore();
    store.state.diffs.isLoading = false;
    store.state.diffs.isTreeLoaded = true;

    extendStore(store);

    wrapper = shallowMount(App, {
      propsData: {
        endpoint: TEST_ENDPOINT,
        endpointMetadata: `${TEST_HOST}/diff/endpointMetadata`,
        endpointBatch: `${TEST_HOST}/diff/endpointBatch`,
        endpointDiffForPath: TEST_ENDPOINT,
        endpointCoverage: `${TEST_HOST}/diff/endpointCoverage`,
        endpointCodequality: `${TEST_HOST}/diff/endpointCodequality`,
        projectPath: 'namespace/project',
        currentUser: {},
        changesEmptyStateIllustration: '',
        dismissEndpoint: '',
        showSuggestPopover: true,
        fileByFileUserPreference: false,
        ...props,
      },
      store,
    });
  }

  beforeEach(() => {
    stubPerformanceWebAPI();

    mock = new MockAdapter(axios);
    mock.onGet(TEST_ENDPOINT).reply(HTTP_STATUS_OK, {});
  });

  describe('EE codequality diff', () => {
    it('fetches code quality data when endpoint is provided', () => {
      createComponent();
      jest.spyOn(wrapper.vm, 'fetchCodequality');
      wrapper.vm.fetchData(false);

      expect(wrapper.vm.fetchCodequality).toHaveBeenCalled();
    });

    it('does not fetch code quality data when endpoint is blank', () => {
      createComponent({ endpointCodequality: '' });
      jest.spyOn(wrapper.vm, 'fetchCodequality');
      wrapper.vm.fetchData(false);

      expect(wrapper.vm.fetchCodequality).not.toHaveBeenCalled();
    });
  });
});
