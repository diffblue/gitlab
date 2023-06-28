import { GlCollapsibleListbox } from '@gitlab/ui';
import fuzzaldrinPlus from 'fuzzaldrin-plus';
import { shallowMount } from '@vue/test-utils';
import StreamFilters from 'ee/audit_events/components/stream/stream_filters.vue';
import { AUDIT_STREAMS_FILTERING } from 'ee/audit_events/constants';
import { mockExternalDestinations, mockAuditEventDefinitions } from '../../mock_data';

const EXPECTED_ITEMS = [
  {
    text: 'Selected',
    options: [
      { text: 'Add gpg key', value: 'add_gpg_key' },
      { text: 'User created', value: 'user_created' },
    ],
  },
  { text: 'User management', options: [{ text: 'User blocked', value: 'user_blocked' }] },
  {
    text: 'Compliance management',
    options: [{ text: 'Project unarchived', value: 'project_unarchived' }],
  },
];

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
      items: EXPECTED_ITEMS,
      selected: mockExternalDestinations[1].eventTypeFilters,
      showSelectAllButtonLabel: AUDIT_STREAMS_FILTERING.SELECT_ALL,
      resetButtonLabel: AUDIT_STREAMS_FILTERING.UNSELECT_ALL,
      headerText: AUDIT_STREAMS_FILTERING.SELECT_EVENTS,
      noResultsText: StreamFilters.i18n.noResultsText,
      searchPlaceholder: StreamFilters.i18n.searchPlaceholder,
      multiple: true,
      searchable: true,
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
      createComponent({ value: ['add_gpg_key'] });

      expect(findCollapsibleListbox().props('toggleText')).toBe('Add gpg key');
    });

    it('displays a comma-separated list of humanized event names when 3 events are selected', () => {
      createComponent({
        value: ['add_gpg_key', 'user_created', 'user_blocked'],
      });

      expect(findCollapsibleListbox().props('toggleText')).toBe(
        'Add gpg key, User created, User blocked',
      );
    });

    it('appends "+1 more" when 4 events are selected', () => {
      createComponent({
        value: ['add_gpg_key', 'user_created', 'user_blocked', 'project_unarchived'],
      });

      expect(findCollapsibleListbox().props('toggleText')).toBe(
        'Add gpg key, User created, User blocked +1 more',
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

  describe('search', () => {
    beforeEach(() => {
      jest.spyOn(fuzzaldrinPlus, 'filter');
    });

    it('does not filter items if searchTerm is empty string', async () => {
      await findCollapsibleListbox().vm.$emit('search', '');

      expect(fuzzaldrinPlus.filter).not.toHaveBeenCalled();
      expect(findCollapsibleListbox().props('items')).toMatchObject(EXPECTED_ITEMS);
    });

    it('filters items correctly when searching', async () => {
      // Omit 'e' in 'user' to test for fuzzy search
      await findCollapsibleListbox().vm.$emit('search', 'usr');

      const expected = [
        {
          text: 'Selected',
          options: [{ text: 'User created', value: 'user_created' }],
        },
        {
          text: 'User management',
          options: [{ text: 'User blocked', value: 'user_blocked' }],
        },
      ];
      expect(findCollapsibleListbox().props('items')).toMatchObject(expected);
      expect(fuzzaldrinPlus.filter).toHaveBeenCalled();
    });
  });

  describe('groups', () => {
    it('renders "Selected" group with selected items', () => {
      createComponent({
        value: ['add_gpg_key', 'user_created', 'user_blocked'],
      });

      const expected = [
        {
          text: 'Selected',
          options: [
            { text: 'Add gpg key', value: 'add_gpg_key' },
            { text: 'User created', value: 'user_created' },
            { text: 'User blocked', value: 'user_blocked' },
          ],
        },
        {
          text: 'Compliance management',
          options: [{ text: 'Project unarchived', value: 'project_unarchived' }],
        },
      ];
      expect(findCollapsibleListbox().props('items')).toMatchObject(expected);
    });

    it('does not render "Selected" group if no items are selected', () => {
      createComponent({
        value: [],
      });

      expect(
        findCollapsibleListbox()
          .props('items')
          .map((group) => group.text),
      ).not.toContain('Selected');
    });

    it('renders only "Selected" group if all items are selected', () => {
      createComponent({
        value: ['add_gpg_key', 'user_created', 'user_blocked', 'project_unarchived'],
      });

      const items = findCollapsibleListbox().props('items');
      expect(items).toHaveLength(1);
      expect(items[0].text).toBe('Selected');
    });
  });
});
