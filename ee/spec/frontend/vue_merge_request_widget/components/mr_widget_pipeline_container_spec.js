import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { mockStore } from 'jest/vue_merge_request_widget/mock_data';
import MergeTrainPositionIndicator from 'ee/vue_merge_request_widget/components/merge_train_position_indicator.vue';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import MrWidgetPipelineContainer from '~/vue_merge_request_widget/components/mr_widget_pipeline_container.vue';
import { MT_MERGE_STRATEGY, MWPS_MERGE_STRATEGY } from '~/vue_merge_request_widget/constants';

describe('MrWidgetPipelineContainer', () => {
  let wrapper;
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
    mock.onGet().reply(HTTP_STATUS_OK, {});
  });

  const factory = (method = shallowMount, mrUpdates = {}, provide = {}) => {
    wrapper = method.call(this, MrWidgetPipelineContainer, {
      propsData: {
        mr: { ...mockStore, ...mrUpdates },
      },
      provide: {
        ...provide,
      },
      attachTo: document.body,
    });
  };

  afterEach(() => {
    mock.restore();
  });

  describe('merge train indicator', () => {
    it('should render the merge train indicator if the MR is open and is on the merge train', () => {
      factory(shallowMount, {
        isOpen: true,
        autoMergeStrategy: MT_MERGE_STRATEGY,
      });

      expect(wrapper.findComponent(MergeTrainPositionIndicator).exists()).toBe(false);
    });

    it('should not render the merge train indicator if the MR is closed', () => {
      factory(shallowMount, {
        isOpen: false,
        autoMergeStrategy: MT_MERGE_STRATEGY,
      });

      expect(wrapper.findComponent(MergeTrainPositionIndicator).exists()).toBe(false);
    });

    it('should not render the merge train indicator if the MR is not on the merge train', () => {
      factory(shallowMount, {
        isOpen: true,
        autoMergeStrategy: MWPS_MERGE_STRATEGY,
      });

      expect(wrapper.findComponent(MergeTrainPositionIndicator).exists()).toBe(false);
    });
  });
});
