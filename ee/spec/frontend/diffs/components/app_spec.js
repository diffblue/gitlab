import { shallowMount } from '@vue/test-utils';

import Vue from 'vue';
import { TEST_HOST } from 'spec/test_constants';
import App from '~/diffs/components/app.vue';
import store from '~/mr_notes/stores';

const TEST_ENDPOINT = `${TEST_HOST}/diff/endpoint`;

jest.mock('~/mr_notes/stores', () => jest.requireActual('helpers/mocks/mr_notes/stores'));

Vue.config.ignoredElements = ['copy-code'];

describe('diffs/components/app', () => {
  const createComponent = (props = {}) => {
    store.reset();

    store.getters.isNotesFetched = false;
    store.getters.getNoteableData = {
      current_user: {
        can_create_note: true,
      },
    };
    store.getters['diffs/flatBlobsList'] = [];
    store.getters['diffs/isBatchLoading'] = false;
    store.getters['diffs/isBatchLoadingError'] = false;
    store.getters['diffs/whichCollapsedTypes'] = { any: false };

    store.state.diffs.isLoading = false;
    store.state.diffs.isTreeLoaded = true;

    return shallowMount(App, {
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
      mocks: {
        $store: store,
      },
    });
  };

  describe('EE codequality diff', () => {
    it('fetches code quality data when endpoint is provided', () => {
      const wrapper = createComponent();
      jest.spyOn(wrapper.vm, 'fetchCodequality');
      wrapper.vm.fetchData(false);

      expect(wrapper.vm.fetchCodequality).toHaveBeenCalled();
    });

    it('does not fetch code quality data when endpoint is blank', () => {
      const wrapper = createComponent({ endpointCodequality: '' });
      jest.spyOn(wrapper.vm, 'fetchCodequality');
      wrapper.vm.fetchData(false);

      expect(wrapper.vm.fetchCodequality).not.toHaveBeenCalled();
    });
  });
});
