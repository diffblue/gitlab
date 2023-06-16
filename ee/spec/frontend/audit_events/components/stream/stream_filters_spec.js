import { GlCollapsibleListbox } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import StreamFilters from 'ee/audit_events/components/stream/stream_filters.vue';
import { AUDIT_STREAMS_FILTERING } from 'ee/audit_events/constants';
import {
  mockExternalDestinations,
  mockAuditEventDefinitions,
  mockStreamFiltersOptions,
} from '../../mock_data';

describe('StreamWithFilters', () => {
  let wrapper;

  const createComponent = (props) => {
    wrapper = shallowMount(StreamFilters, {
      propsData: {
        value: mockExternalDestinations[1].eventTypeFilters,
        ...props,
      },
      provide: {
        auditEventDefinitions: mockAuditEventDefinitions,
      },
    });
  };

  const findCollapsibleListbox = () => wrapper.findComponent(GlCollapsibleListbox);

  beforeEach(() => {
    createComponent();
  });

  it('renders correctly', () => {
    expect(findCollapsibleListbox().props()).toMatchObject({
      items: mockStreamFiltersOptions,
      selected: mockExternalDestinations[1].eventTypeFilters,
      showSelectAllButtonLabel: AUDIT_STREAMS_FILTERING.SELECT_ALL,
      resetButtonLabel: AUDIT_STREAMS_FILTERING.UNSELECT_ALL,
      headerText: AUDIT_STREAMS_FILTERING.SELECT_EVENTS,
      multiple: true,
      toggleClass: 'gl-max-w-full',
    });
    expect(findCollapsibleListbox().classes('gl-max-w-full')).toBe(true);
  });

  describe('toggleText', () => {
    it('displays a placeholder when no events are selected', () => {
      createComponent({ value: [] });

      expect(findCollapsibleListbox().props('toggleText')).toBe(
        AUDIT_STREAMS_FILTERING.SELECT_EVENTS,
      );
    });

    it('displays a humanized event name when 1 event is selected', () => {
      createComponent({ value: ['repository_download_operation'] });

      expect(findCollapsibleListbox().props('toggleText')).toBe('Repository download operation');
    });

    it('displays a comma-separated list of humanized event names when 3 events are selected', () => {
      createComponent({
        value: [
          'repository_download_operation',
          'update_merge_approval_rule',
          'create_merge_approval_rule',
        ],
      });

      expect(findCollapsibleListbox().props('toggleText')).toBe(
        'Repository download operation, Update merge approval rule, Create merge approval rule',
      );
    });

    it('appends "+1 more" when 4 events are selected', () => {
      createComponent({
        value: [
          'repository_download_operation',
          'update_merge_approval_rule',
          'create_merge_approval_rule',
          'project_unarchived',
        ],
      });

      expect(findCollapsibleListbox().props('toggleText')).toBe(
        'Repository download operation, Update merge approval rule, Create merge approval rule +1 more',
      );
    });
  });

  describe('events', () => {
    it('emits `input` event when selecting event', () => {
      findCollapsibleListbox().vm.$emit('select', mockExternalDestinations[1].eventTypeFilters);

      expect(wrapper.emitted('input')).toStrictEqual([
        [mockExternalDestinations[1].eventTypeFilters],
      ]);
    });

    it('emits `input` with empty array when unselecting all', () => {
      findCollapsibleListbox().vm.$emit('reset');

      expect(wrapper.emitted('input')).toEqual([[[]]]);
    });

    it('emits `input` with all events when selecting all', () => {
      findCollapsibleListbox().vm.$emit('select-all');

      expect(wrapper.emitted('input')).toEqual([
        [mockAuditEventDefinitions.map((definition) => definition.event_name)],
      ]);
    });
  });
});
