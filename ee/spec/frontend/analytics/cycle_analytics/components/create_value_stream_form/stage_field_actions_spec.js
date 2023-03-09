import { shallowMount } from '@vue/test-utils';
import StageFieldActions from 'ee/analytics/cycle_analytics/components/create_value_stream_form/stage_field_actions.vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

const stageCount = 3;

describe('StageFieldActions', () => {
  function createComponent({ index = 0, canRemove = false }) {
    return extendedWrapper(
      shallowMount(StageFieldActions, {
        propsData: {
          index,
          stageCount,
          canRemove,
        },
      }),
    );
  }

  let wrapper = null;
  const findMoveDownBtn = (index = 0) => wrapper.findByTestId(`stage-action-move-down-${index}`);
  const findMoveUpBtn = (index = 0) => wrapper.findByTestId(`stage-action-move-up-${index}`);
  const findHideBtn = (index = 0) => wrapper.findByTestId(`stage-action-hide-${index}`);
  const findRemoveBtn = (index = 0) => wrapper.findByTestId(`stage-action-remove-${index}`);

  beforeEach(() => {
    wrapper = createComponent({});
  });

  it('will render the move up action', () => {
    expect(findMoveUpBtn().exists()).toBe(true);
  });

  it('will render the move down action', () => {
    expect(findMoveDownBtn().exists()).toBe(true);
  });

  it('will render the hide action', () => {
    expect(findHideBtn().exists()).toBe(true);
  });

  it('does not render the remove action', () => {
    expect(findRemoveBtn().exists()).toBe(false);
  });

  it('disables the move up button', () => {
    expect(findMoveUpBtn().props('disabled')).toBe(true);
  });

  it('when the down button is clicked will emit a `move` event', () => {
    findMoveDownBtn().vm.$emit('click');
    expect(wrapper.emitted('move')[0]).toEqual([{ direction: 'DOWN', index: 0 }]);
  });

  it('when the up button is clicked will emit a `move` event', () => {
    findMoveUpBtn().vm.$emit('click');
    expect(wrapper.emitted('move')[0]).toEqual([{ direction: 'UP', index: 0 }]);
  });

  it('when the hide button is clicked will emit a `move` event', () => {
    findHideBtn().vm.$emit('click');
    expect(wrapper.emitted('hide')[0]).toEqual([0]);
  });

  describe('when the current index is the same as the total number of stages', () => {
    beforeEach(() => {
      wrapper = createComponent({ index: 2 });
    });

    it('disables the move down button', () => {
      expect(findMoveDownBtn(2).props('disabled')).toBe(true);
    });
  });

  describe('when canRemove=true', () => {
    beforeEach(() => {
      wrapper = createComponent({ canRemove: true });
    });

    it('will render the remove action', () => {
      expect(findRemoveBtn().exists()).toBe(true);
    });

    it('does not render the hide action', () => {
      expect(findHideBtn().exists()).toBe(false);
    });
  });
});
