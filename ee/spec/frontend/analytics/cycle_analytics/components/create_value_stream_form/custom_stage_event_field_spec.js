import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import {
  i18n,
  ERRORS,
} from 'ee/analytics/cycle_analytics/components/create_value_stream_form/constants';
import CustomStageEventField from 'ee/analytics/cycle_analytics/components/create_value_stream_form/custom_stage_event_field.vue';
import { customStageEvents as stageEvents } from '../../mock_data';

const formatStartEventOpts = (_events) => [
  { text: 'Select start event', value: null },
  ..._events
    .filter((ev) => ev.canBeStartEvent)
    .map(({ name: text, identifier: value }) => ({ text, value })),
];

const index = 0;
const eventType = 'stage-start-event';
const fieldLabel = i18n.FORM_FIELD_START_EVENT;
const selectedEventName = i18n.SELECT_START_EVENT;
const eventsList = formatStartEventOpts(stageEvents);
const selectedEventIndex = 1; // index `0` is the default select text
const firstEvent = eventsList[selectedEventIndex];
const identifierError = ERRORS.START_EVENT_REQUIRED;

const defaultProps = {
  index,
  eventType,
  eventsList,
  fieldLabel,
  selectedEventName,
};

describe('CustomStageEventField', () => {
  function createComponent(props = {}) {
    return shallowMountExtended(CustomStageEventField, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  }

  let wrapper = null;

  const findEventField = () => wrapper.findByTestId(`custom-stage-${eventType}-${index}`);
  const findEventDropdown = () => findEventField().findComponent(GlDropdown);
  const findEventDropdownItems = () => findEventField().findAllComponents(GlDropdownItem);
  const findEventDropdownItem = (itemIndex = 0) => findEventDropdownItems().at(itemIndex);

  beforeEach(() => {
    wrapper = createComponent();
  });

  describe('Event dropdown', () => {
    it('renders the event dropdown', () => {
      expect(findEventField().exists()).toBe(true);
      expect(findEventField().attributes('label')).toBe(fieldLabel);
      expect(findEventDropdown().attributes('disabled')).toBeUndefined();
      expect(findEventDropdown().attributes('text')).toBe(selectedEventName);
    });

    it('renders each item in the event list', () => {
      const ev = findEventDropdownItems().wrappers.map((d) => d.text());
      const eventsListText = eventsList.map(({ text }) => text);

      expect(eventsListText).toEqual(ev);
    });

    it('emits the `update-identifier` event when an event is selected', () => {
      expect(wrapper.emitted('update-identifier')).toBeUndefined();

      findEventDropdownItem(selectedEventIndex).vm.$emit('click');

      expect(wrapper.emitted('update-identifier')[0]).toEqual([firstEvent.value]);
    });

    it('sets disables the dropdown when the disabled prop is set', () => {
      expect(findEventDropdown().attributes('disabled')).toBeUndefined();

      wrapper = createComponent({ disabled: true });

      expect(findEventDropdown().attributes('disabled')).toBeDefined();
    });
  });

  describe('with an event field error', () => {
    beforeEach(() => {
      wrapper = createComponent({
        hasIdentifierError: true,
        identifierError,
      });
    });

    it('sets the form group error state', () => {
      expect(findEventField().attributes('state')).toBe('true');
      expect(findEventField().attributes('invalid-feedback')).toBe(identifierError);
    });
  });
});
