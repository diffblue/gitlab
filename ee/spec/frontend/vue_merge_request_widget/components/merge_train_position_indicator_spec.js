import { shallowMount } from '@vue/test-utils';
import MergeTrainPositionIndicator from 'ee/vue_merge_request_widget/components/merge_train_position_indicator.vue';
import { trimText } from 'helpers/text_helper';

describe('MergeTrainPositionIndicator', () => {
  let wrapper;

  const factory = (propsData) => {
    wrapper = shallowMount(MergeTrainPositionIndicator, {
      propsData,
    });
  };

  describe('computed', () => {
    describe('template', () => {
      it('should render the correct message', () => {
        factory({ mergeTrainIndex: 3 });

        expect(trimText(wrapper.text())).toBe(
          'Added to the merge train. There are 4 merge requests waiting to be merged',
        );
      });

      it('should change the merge train message when the position is 1', () => {
        factory({ mergeTrainIndex: 0 });

        expect(trimText(wrapper.text())).toBe(
          'A new merge train has started and this merge request is the first of the queue.',
        );
      });
    });
  });
});
