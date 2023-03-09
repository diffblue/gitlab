import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import {
  i18n,
  ERRORS,
} from 'ee/analytics/cycle_analytics/components/create_value_stream_form/constants';
import CustomStageEventLabelField from 'ee/analytics/cycle_analytics/components/create_value_stream_form/custom_stage_event_label_field.vue';
import LabelsSelector from 'ee/analytics/cycle_analytics/components/labels_selector.vue';
import { groupLabels as initialGroupLabels } from '../../mock_data';

const index = 0;
const eventType = 'start-event';
const fieldLabel = i18n.FORM_FIELD_START_EVENT_LABEL;
const labelError = ERRORS.INVALID_EVENT_PAIRS;
const [selectedLabel, secondLabel] = initialGroupLabels;
const selectedLabelNames = [selectedLabel.title, secondLabel.title];

const defaultProps = {
  index,
  eventType,
  fieldLabel,
  requiresLabel: true,
  initialGroupLabels,
  labelError,
  selectedLabelNames: [],
};

describe('CustomStageEventLabelField', () => {
  function createComponent(props = {}) {
    return shallowMountExtended(CustomStageEventLabelField, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  }

  let wrapper = null;

  const findEventLabelField = () =>
    wrapper.findByTestId(`custom-stage-${eventType}-label-${index}`);
  const findEventLabelDropdown = () => findEventLabelField().findComponent(LabelsSelector);
  const findEventLabelDropdownProp = (prop) => findEventLabelDropdown().props(prop);

  beforeEach(() => {
    wrapper = createComponent();
  });

  describe('Label dropdown', () => {
    it('renders the event dropdown', () => {
      expect(findEventLabelField().exists()).toBe(true);
      expect(findEventLabelField().attributes('label')).toBe(fieldLabel);
    });

    it('has no selected labels', () => {
      const selected = findEventLabelDropdownProp('selectedLabelNames');

      expect(selected).toEqual([]);
    });

    it('emits the `update-label` event when a label is selected', () => {
      expect(wrapper.emitted('update-label')).toBeUndefined();

      findEventLabelDropdown().vm.$emit('select-label', selectedLabel.id);

      expect(wrapper.emitted('update-label')[0]).toEqual([selectedLabel.id]);
    });
  });

  describe('with selected labels', () => {
    beforeEach(() => {
      wrapper = createComponent({ selectedLabelNames });
    });

    it('sets the selected labels', () => {
      const selected = findEventLabelDropdownProp('selectedLabelNames');

      expect(selected).toEqual(selectedLabelNames);
    });
  });

  describe('with `requiresLabel=false`', () => {
    beforeEach(() => {
      wrapper = createComponent({ requiresLabel: false });
    });

    it('sets the form group error state', () => {
      expect(findEventLabelField().exists()).toBe(false);
    });
  });

  describe('with an event field error', () => {
    beforeEach(() => {
      wrapper = createComponent({
        hasLabelError: true,
        labelError,
      });
    });

    it('sets the form group error state', () => {
      expect(findEventLabelField().attributes('state')).toBe('true');
      expect(findEventLabelField().attributes('invalid-feedback')).toBe(labelError);
    });
  });
});
