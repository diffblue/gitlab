import { GlAvatarLink, GlAvatarLabeled } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import BoardSettingsListTypes from 'ee_component/boards/components/board_settings_list_types.vue';

describe('BoardSettingsListType', () => {
  let wrapper;
  const activeList = {
    milestone: {
      webUrl: 'https://gitlab.com/h5bp/html5-boilerplate/-/milestones/1',
      title: 'Backlog',
    },
    iteration: {
      webUrl: 'https://gitlab.com/h5bp/-/iterations/1',
      title: 'Sprint 1',
    },
    assignee: { webUrl: 'https://gitlab.com/root', name: 'root', username: 'root' },
  };
  const createComponent = (props) => {
    wrapper = shallowMount(BoardSettingsListTypes, {
      propsData: { ...props, activeList },
    });
  };

  describe('when list type is "milestone"', () => {
    it('renders the correct milestone text', () => {
      createComponent({ activeId: 1, boardListType: 'milestone' });

      expect(wrapper.find('.js-list-title').text()).toBe('Backlog');
    });

    it('renders the correct list type text', () => {
      createComponent({ activeId: 1, boardListType: 'milestone' });

      expect(wrapper.find('.js-list-label').text()).toBe('Milestone');
    });
  });

  describe('when list type is "iteration"', () => {
    it('renders the correct milestone text', () => {
      createComponent({ activeId: 1, boardListType: 'iteration' });

      expect(wrapper.find('.js-list-title').text()).toBe('Sprint 1');
    });

    it('renders the correct list type text', () => {
      createComponent({ activeId: 1, boardListType: 'iteration' });

      expect(wrapper.find('.js-list-label').text()).toBe('Iteration');
    });
  });

  describe('when list type is "assignee"', () => {
    it('renders gl-avatar-link with correct href', () => {
      createComponent({ activeId: 1, boardListType: 'assignee' });

      expect(wrapper.findComponent(GlAvatarLink).exists()).toBe(true);
      expect(wrapper.findComponent(GlAvatarLink).attributes('href')).toBe(
        'https://gitlab.com/root',
      );
    });

    it('renders gl-avatar-labeled with "root" as username and name as "root"', () => {
      createComponent({ activeId: 1, boardListType: 'assignee' });

      expect(wrapper.findComponent(GlAvatarLabeled).exists()).toBe(true);
      expect(wrapper.findComponent(GlAvatarLabeled).attributes('label')).toBe('root');
      expect(wrapper.findComponent(GlAvatarLabeled).attributes('sublabel')).toBe('@root');
    });

    it('renders the correct list type text', () => {
      createComponent({ activeId: 1, boardListType: 'assignee' });

      expect(wrapper.find('.js-list-label').text()).toBe('Assignee');
    });
  });
});
