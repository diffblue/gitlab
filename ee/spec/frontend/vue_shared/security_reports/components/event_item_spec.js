import { GlButton } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import Component from 'ee/vue_shared/security_reports/components/event_item.vue';
import NoteHeader from '~/notes/components/note_header.vue';

describe('Event Item', () => {
  let wrapper;

  const mountComponent = (propsData, mountFn = shallowMountExtended) => {
    wrapper = mountFn(Component, {
      ...propsData,
    });
  };

  const noteHeader = () => wrapper.findComponent(NoteHeader);

  describe('initial state', () => {
    const propsData = {
      id: 123,
      createdAt: 'createdAt',
      headerMessage: 'header message',
      author: {
        name: 'Tanuki',
        username: 'gitlab',
      },
    };

    const slots = { default: '<p>Test</p>' };

    beforeEach(() => {
      mountComponent({ propsData, slots });
    });

    it('passes the expected values to the note header component', () => {
      expect(noteHeader().props()).toMatchObject({
        noteId: propsData.id,
        author: propsData.author,
        createdAt: propsData.createdAt,
        showSpinner: false,
      });
    });

    it('uses the fallback icon', () => {
      expect(wrapper.props().iconName).toBe('plus');
    });

    it('uses the fallback icon class', () => {
      expect(wrapper.props().iconClass).toBe('ci-status-icon-success');
    });

    it('renders the action buttons container', () => {
      expect(wrapper.findByTestId('action-buttons').exists()).toBe(true);
    });

    it('renders the default slot', () => {
      expect(wrapper.html()).toEqual(expect.stringContaining('<p>Test</p>'));
    });
  });

  describe('with action buttons', () => {
    const propsData = {
      author: {
        name: 'Tanuki',
        username: 'gitlab',
      },
      actionButtons: [
        {
          iconName: 'pencil',
          onClick: jest.fn(),
          title: 'Foo Action',
        },
        {
          iconName: 'remove',
          onClick: jest.fn(),
          title: 'Bar Action',
        },
      ],
    };

    beforeEach(() => {
      mountComponent({ propsData }, mountExtended);
    });

    it('renders the action buttons container', () => {
      expect(wrapper.findByTestId('action-buttons').exists()).toBe(true);
    });

    it('renders the action buttons', () => {
      const buttons = wrapper.findAllComponents(GlButton);

      expect(buttons).toHaveLength(2);

      propsData.actionButtons.forEach((button, index) => {
        expect(buttons.at(index).props('icon')).toBe(button.iconName);
        expect(buttons.at(index).attributes('title')).toBe(button.title);
      });
    });

    it('emits the button events when clicked', async () => {
      const buttons = wrapper.findAllComponents(GlButton);

      buttons.at(0).trigger('click');
      await nextTick();
      buttons.at(1).trigger('click');
      await nextTick();

      expect(propsData.actionButtons[0].onClick).toHaveBeenCalledTimes(1);
      expect(propsData.actionButtons[1].onClick).toHaveBeenCalledTimes(1);
    });
  });

  describe('created at timestamp', () => {
    it('shows the timestamp when there is one', () => {
      const date = new Date().toISOString();
      mountComponent({ propsData: { author: {}, createdAt: date } });

      expect(noteHeader().props('createdAt')).toBe(date);
      expect(noteHeader().text()).toBe('·');
    });

    it(`does not show timestamp when there isn't one`, () => {
      mountComponent({ propsData: { author: {} } });

      expect(noteHeader().props('createdAt')).toBe('');
      expect(noteHeader().text()).not.toContain('·');
    });
  });
});
