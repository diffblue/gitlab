import { shallowMount } from '@vue/test-utils';
import { GlLoadingIcon, GlEmptyState } from '@gitlab/ui';
import ValueStreamEmptyState from 'ee/analytics/cycle_analytics/components/value_stream_empty_state.vue';
import {
  EMPTY_STATE_ACTION_TEXT,
  EMPTY_STATE_SECONDARY_TEXT,
  EMPTY_STATE_FILTER_ERROR_TITLE,
  EMPTY_STATE_TITLE,
  EMPTY_STATE_FILTER_ERROR_DESCRIPTION,
  EMPTY_STATE_DESCRIPTION,
} from 'ee/analytics/cycle_analytics/constants';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

const emptyStateSvgPath = '/path/to/svg';

const createComponent = (props = {}) =>
  extendedWrapper(
    shallowMount(ValueStreamEmptyState, {
      propsData: {
        emptyStateSvgPath,
        isLoading: false,
        hasDateRangeError: false,
        ...props,
      },
      stubs: { GlEmptyState },
    }),
  );

describe('ValueStreamEmptyState', () => {
  let wrapper = null;

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findTitle = () => findEmptyState().props('title');
  const findDescription = () => findEmptyState().props('description');
  const findPrimaryAction = () => wrapper.findByTestId('create-value-stream-button');
  const findSecondaryAction = () => wrapper.findByTestId('learn-more-link');

  describe('default state', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('does not render the loading icon', () => {
      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(false);
    });

    it('renders the empty state title message', () => {
      expect(findTitle()).toEqual(EMPTY_STATE_TITLE);
    });

    it('renders the empty state description message', () => {
      expect(findDescription()).toBe(EMPTY_STATE_DESCRIPTION);
    });

    it('renders the create value stream button', () => {
      expect(findPrimaryAction().exists()).toBe(true);
      expect(findPrimaryAction().text()).toContain(EMPTY_STATE_ACTION_TEXT);
    });

    it('renders the learn more button', () => {
      expect(findSecondaryAction().exists()).toBe(true);
      expect(findSecondaryAction().text()).toBe(EMPTY_STATE_SECONDARY_TEXT);
      expect(findSecondaryAction().attributes('href')).toBe(
        '/help/user/group/value_stream_analytics/index#custom-value-streams',
      );
    });
  });

  describe('isLoading = true', () => {
    beforeEach(() => {
      wrapper = createComponent({ isLoading: true });
    });

    it('renders the loading icon', () => {
      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
    });
  });

  describe('hasDateRangeError = true', () => {
    beforeEach(() => {
      wrapper = createComponent({ hasDateRangeError: true });
    });

    it('renders the error title message', () => {
      expect(findTitle()).toEqual(EMPTY_STATE_FILTER_ERROR_TITLE);
    });

    it('renders the error description message', () => {
      expect(findDescription()).toBe(EMPTY_STATE_FILTER_ERROR_DESCRIPTION);
    });

    it('does not render the create value stream button', () => {
      expect(findPrimaryAction().exists()).toBe(false);
    });

    it('does not render the learn more button', () => {
      expect(findSecondaryAction().exists()).toBe(false);
    });
  });
});
