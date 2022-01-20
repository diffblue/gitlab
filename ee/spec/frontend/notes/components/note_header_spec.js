import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import GitlabTeamMemberBadge from 'ee/vue_shared/components/user_avatar/badges/gitlab_team_member_badge.vue';
import NoteHeader from '~/notes/components/note_header.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

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
    wrapper = shallowMount(NoteHeader, {
      localVue,
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
    ({ props, expected }) => {
      createComponent(props);

      // Wait for dynamic imports to resolve
      return new Promise(setImmediate).then(() => {
        expect(wrapper.findComponent(GitlabTeamMemberBadge).exists()).toBe(expected);
      });
    },
  );
});
