import Vue from 'vue';
import Vuex from 'vuex';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GitlabTeamMemberBadge from 'ee/vue_shared/components/user_avatar/badges/gitlab_team_member_badge.vue';
import NoteHeader from '~/notes/components/note_header.vue';

Vue.use(Vuex);

describe('NoteHeader component', () => {
  let wrapper;

  const author = {
    avatar_url: null,
    id: 1,
    name: 'Root',
    path: '/root',
    state: 'active',
    username: 'root',
  };

  const createComponent = (props) => {
    wrapper = shallowMountExtended(NoteHeader, {
      store: new Vuex.Store(),
      propsData: { ...props },
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
});
