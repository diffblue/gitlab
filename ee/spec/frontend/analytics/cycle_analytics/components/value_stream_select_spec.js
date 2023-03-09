import { GlDropdown } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import ValueStreamSelect from 'ee/analytics/cycle_analytics/components/value_stream_select.vue';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { findDropdownItemText } from '../helpers';
import { valueStreams, defaultStageConfig } from '../mock_data';

Vue.use(Vuex);

describe('ValueStreamSelect', () => {
  let wrapper = null;
  let trackingSpy = null;

  const deleteValueStreamMock = jest.fn(() => Promise.resolve());
  const mockEvent = { preventDefault: jest.fn() };
  const mockToastShow = jest.fn();
  const streamName = 'Cool stream';
  const selectedValueStream = valueStreams[0];
  const deleteValueStreamError = 'Cannot delete default value stream';

  const fakeStore = ({ initialState = {} }) =>
    new Vuex.Store({
      state: {
        isCreatingValueStream: false,
        isDeletingValueStream: false,
        createValueStreamErrors: {},
        deleteValueStreamError: null,
        valueStreams: [],
        selectedValueStream: {},
        defaultStageConfig,
        ...initialState,
      },
      actions: {
        deleteValueStream: deleteValueStreamMock,
      },
    });

  const createComponent = ({ data = {}, initialState = {}, mountFn = shallowMount } = {}) =>
    extendedWrapper(
      mountFn(ValueStreamSelect, {
        store: fakeStore({ initialState }),
        data() {
          return {
            ...data,
          };
        },
        mocks: {
          $toast: {
            show: mockToastShow,
          },
        },
      }),
    );

  const findModal = (modal) => wrapper.find(`[data-testid="${modal}-value-stream-modal"]`);
  const submitModal = (modal) => findModal(modal).vm.$emit('primary', mockEvent);
  const findSelectValueStreamDropdown = () => wrapper.findComponent(GlDropdown);
  const findSelectValueStreamDropdownOptions = () => findDropdownItemText(wrapper);
  const findCreateValueStreamButton = () => wrapper.findByTestId('create-value-stream-button');
  const findEditValueStreamButton = () => wrapper.findByTestId('edit-value-stream');
  const findDeleteValueStreamButton = () => wrapper.findByTestId('delete-value-stream');

  afterEach(() => {
    unmockTracking();
  });

  describe('with value streams available', () => {
    describe('default behaviour', () => {
      beforeEach(() => {
        wrapper = createComponent({
          mountFn: mount,
          initialState: {
            valueStreams,
          },
        });
        trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
      });

      it('does not display the create value stream button', () => {
        expect(findCreateValueStreamButton().exists()).toBe(false);
      });

      it('displays the select value stream dropdown', () => {
        expect(findSelectValueStreamDropdown().exists()).toBe(true);
      });

      it('renders each value stream including a create button', () => {
        const opts = findSelectValueStreamDropdownOptions(wrapper);
        [...valueStreams.map((v) => v.name), 'Create new Value Stream'].forEach((vs) => {
          expect(opts).toContain(vs);
        });
      });
    });

    describe('with a selected value stream', () => {
      beforeEach(() => {
        wrapper = createComponent({
          mountFn: mount,
          initialState: {
            valueStreams,
            selectedValueStream: {
              ...selectedValueStream,
              isCustom: true,
            },
          },
        });
      });

      it('renders a delete option for custom value streams', () => {
        expect(findDeleteValueStreamButton().exists()).toBe(true);
      });

      it('renders an edit option for custom value streams', () => {
        expect(findEditValueStreamButton().exists()).toBe(true);
        expect(findEditValueStreamButton().text()).toBe('Edit');
      });
    });

    describe('with a default value stream', () => {
      beforeEach(() => {
        wrapper = createComponent({ initialState: { valueStreams, selectedValueStream } });
      });

      it('does not render a delete option for default value streams', () => {
        expect(findDeleteValueStreamButton().exists()).toBe(false);
      });

      it('does not render an edit option for default value streams', () => {
        expect(findEditValueStreamButton().exists()).toBe(false);
      });
    });
  });

  describe('Only the default value stream available', () => {
    beforeEach(() => {
      wrapper = createComponent({
        initialState: {
          valueStreams: [{ id: 'default', name: 'default' }],
        },
      });
    });

    it('does not display the create value stream button', () => {
      expect(findCreateValueStreamButton().exists()).toBe(false);
    });

    it('displays the select value stream dropdown', () => {
      expect(findSelectValueStreamDropdown().exists()).toBe(true);
    });

    it('does not render an edit option for default value streams', () => {
      expect(findEditValueStreamButton().exists()).toBe(false);
    });
  });

  describe('No value streams available', () => {
    beforeEach(() => {
      wrapper = createComponent({
        initialState: {
          valueStreams: [],
        },
      });
    });

    it('displays the create value stream button', () => {
      expect(findCreateValueStreamButton().exists()).toBe(true);
    });

    it('does not display the select value stream dropdown', () => {
      expect(findSelectValueStreamDropdown().exists()).toBe(false);
    });

    it('does not render an edit option for default value streams', () => {
      expect(findEditValueStreamButton().exists()).toBe(false);
    });
  });

  describe('Delete value stream modal', () => {
    describe('succeeds', () => {
      beforeEach(() => {
        wrapper = createComponent({
          initialState: {
            valueStreams,
            selectedValueStream: {
              ...selectedValueStream,
              isCustom: true,
            },
          },
        });

        trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);

        submitModal('delete');
      });

      it('calls the "deleteValueStream" event when submitted', () => {
        expect(deleteValueStreamMock).toHaveBeenCalledWith(
          expect.any(Object),
          selectedValueStream.id,
        );
      });

      it('displays a toast message', () => {
        expect(mockToastShow).toHaveBeenCalledWith(
          `'${selectedValueStream.name}' Value Stream deleted`,
        );
      });

      it('sends tracking information', () => {
        expect(trackingSpy).toHaveBeenCalledWith(undefined, 'delete_value_stream', {
          extra: { name: selectedValueStream.name },
        });
      });
    });

    describe('fails', () => {
      beforeEach(() => {
        wrapper = createComponent({
          data: { name: streamName },
          initialState: { deleteValueStreamError },
        });
      });

      it('does not display a toast message', () => {
        expect(mockToastShow).not.toHaveBeenCalled();
      });
    });
  });
});
