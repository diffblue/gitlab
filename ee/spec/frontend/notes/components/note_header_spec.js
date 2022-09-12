import Vue from 'vue';
import Vuex from 'vuex';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GitlabTeamMemberBadge from 'ee/vue_shared/components/user_avatar/badges/gitlab_team_member_badge.vue';
import NoteHeader from '~/notes/components/note_header.vue';
import { AVAILABILITY_STATUS } from '~/set_status_modal/constants';

Vue.use(Vuex);

describe('NoteHeader component', () => {
  let wrapper;

  const findAuthorStatus = () => wrapper.findComponent({ ref: 'authorStatus' });

  const statusHtml =
    '"<span class="user-status-emoji has-tooltip" title="foo bar" data-html="true" data-placement="top"><gl-emoji title="basketball and hoop" data-name="basketball" data-unicode-version="6.0">🏀</gl-emoji></span>"';

  const author = {
    avatar_url: null,
    id: 1,
    name: 'Root',
    path: '/root',
    state: 'active',
    username: 'root',
    show_status: true,
    status_tooltip_html: statusHtml,
    availability: '',
  };

  const createComponent = (props, userAttributes = false) => {
    wrapper = shallowMountExtended(NoteHeader, {
      store: new Vuex.Store(),
      propsData: { ...props },
      provide: {
        glFeatures: {
          removeUserAttributesProjects: userAttributes,
          removeUserAttributesGroups: userAttributes,
        },
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  test.each`
    props                                                   | expected | message1            | message2
    ${{ author: { ...author, is_gitlab_employee: true } }}  | ${true}  | ${'renders'}        | ${'true'}
    ${{ author: { ...author, is_gitlab_employee: false } }} | ${false} | ${"doesn't render"} | ${'false'}
    ${{ author }}                                           | ${false} | ${"doesn't render"} | ${'undefined'}
  `(
    '$message1 GitLab team member badge when `is_gitlab_employee` is $message2',
    async ({ props, expected }) => {
      createComponent(props);

      // Wait for dynamic imports to resolve
      await waitForPromises();

      expect(wrapper.findComponent(GitlabTeamMemberBadge).exists()).toBe(expected);
    },
  );

  it('shows internal note badge tooltip for group context when isInternalNote is true for epics', () => {
    createComponent({ isInternalNote: true, noteableType: 'epic' });

    expect(wrapper.findByTestId('internalNoteIndicator').attributes('title')).toBe(
      'This internal note will always remain confidential',
    );
  });

  describe('when removeUserAttributesGroups feature flag is enabled', () => {
    it('does not render busy status', () => {
      createComponent(
        { author: { ...author, availability: AVAILABILITY_STATUS.BUSY, noteableType: 'epic' } },
        true,
      );

      expect(wrapper.find('.note-header-info').text()).not.toContain('(Busy)');
    });

    it('does not render author status', () => {
      createComponent({ author, noteableType: 'epic' }, true);

      expect(findAuthorStatus().exists()).toBe(false);
    });

    it('does not render username', () => {
      createComponent({ author, noteableType: 'epic' }, true);

      expect(wrapper.find('.note-header-info').text()).not.toContain('@');
    });
  });
});
