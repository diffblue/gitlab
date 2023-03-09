import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import ValueStreamForm from 'ee/analytics/cycle_analytics/components/value_stream_form.vue';
import ValueStreamFormContent from 'ee/analytics/cycle_analytics/components/value_stream_form_content.vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { rawCustomStage, valueStreams, defaultStageConfig } from '../mock_data';

Vue.use(Vuex);

const [selectedValueStream] = valueStreams;
const camelCustomStage = convertObjectPropsToCamelCase(rawCustomStage);
const stages = [camelCustomStage];
const initialData = { name: '', stages: [] };

const fakeStore = ({ state }) =>
  new Vuex.Store({
    state: {
      createValueStreamErrors: {},
      defaultStageConfig,
      ...state,
    },
  });

const createComponent = ({ props = {}, state = {} } = {}) =>
  extendedWrapper(
    shallowMount(ValueStreamForm, {
      store: fakeStore({ state }),
      propsData: {
        defaultStageConfig,
        ...props,
      },
    }),
  );

describe('ValueStreamForm', () => {
  let wrapper = null;

  const findForm = () => wrapper.findComponent(ValueStreamFormContent);
  const findFormProps = () => findForm().props();

  describe('default state', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('renders the form component', () => {
      expect(findForm().exists()).toBe(true);
      expect(findFormProps()).toMatchObject({
        defaultStageConfig,
        initialData,
        isEditing: false,
      });
    });

    it('emits `hidden` when the modal is hidden', () => {
      expect(wrapper.emitted('hidden')).toBeUndefined();

      findForm().vm.$emit('hidden');

      expect(wrapper.emitted('hidden')).toHaveLength(1);
    });
  });

  describe('when editing', () => {
    beforeEach(() => {
      wrapper = createComponent({
        props: { isEditing: true },
        state: { selectedValueStream, stages },
      });
    });

    it('sets the form initialData', () => {
      const props = findFormProps();
      expect(props.initialData).toMatchObject({
        id: selectedValueStream.id,
        name: selectedValueStream.name,
        stages: [
          camelCustomStage,
          ...defaultStageConfig.map(({ custom, name }) => ({ custom, name, hidden: true })),
        ],
      });
    });
  });

  describe('with createValueStreamErrors', () => {
    const nameError = "Name can't be blank";
    beforeEach(() => {
      wrapper = createComponent({
        state: { createValueStreamErrors: { name: nameError } },
      });
    });

    it('sets the form initialFormErrors', () => {
      const props = findFormProps();
      expect(props.initialFormErrors).toEqual({ name: nameError });
    });
  });
});
