import { GlCollapsibleListbox, GlListboxItem, GlAvatarLabeled } from '@gitlab/ui';
import { nextTick } from 'vue';
import { cloneDeep } from 'lodash';
import { shallowMount } from '@vue/test-utils';
import { TEST_HOST } from 'helpers/test_constants';
import waitForPromises from 'helpers/wait_for_promises';
import Api from 'ee/api';
import ApproversSelect from 'ee/approvals/components/approvers_select.vue';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';
import { TYPE_USER } from 'ee/approvals/constants';

const TEST_PROJECT_ID = '17';
const TEST_GROUP_AVATAR = `${TEST_HOST}/group-avatar.png`;
const TEST_USER_AVATAR = `${TEST_HOST}/user-avatar.png`;
const TEST_GROUPS = [
  { id: 1, full_name: 'GitLab Org', full_path: 'gitlab/org', avatar_url: null },
  {
    id: 2,
    full_name: 'Lorem Ipsum',
    full_path: 'lorem-ipsum',
    avatar_url: TEST_GROUP_AVATAR,
  },
];
const TEST_USERS = [
  { id: 1, name: 'Dolar', username: 'dolar', avatar_url: TEST_USER_AVATAR },
  { id: 3, name: 'Sit', username: 'sit', avatar_url: TEST_USER_AVATAR },
];

const TERM = 'lorem';

describe('Approvers Selector', () => {
  let wrapper;

  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findAllListboxItems = () => wrapper.findAllComponents(GlListboxItem);
  const findAvatar = (index) => findAllListboxItems().at(index).findComponent(GlAvatarLabeled);
  const search = (searchString) => findListbox().vm.$emit('search', searchString);

  const createComponent = (props = {}) => {
    wrapper = shallowMount(ApproversSelect, {
      propsData: {
        namespaceId: TEST_PROJECT_ID,
        ...props,
      },
      stubs: { GlCollapsibleListbox },
    });
  };
  const openListbox = () => findListbox().vm.$emit('shown');

  beforeEach(() => {
    jest.spyOn(Api, 'groups').mockResolvedValue(TEST_GROUPS);
    jest.spyOn(Api, 'projectGroups').mockResolvedValue(TEST_GROUPS);
    jest.spyOn(Api, 'projectUsers').mockReturnValue(Promise.resolve(TEST_USERS));
  });

  describe('Listbox', () => {
    it('is rendered', () => {
      createComponent();
      expect(findListbox().props()).toMatchObject({
        toggleText: ApproversSelect.i18n.toggleText,
        noCaret: true,
        searchable: true,
        searching: false,
        variant: 'default',
        category: 'secondary',
      });
    });

    it('variant is set to danger if is invalid', () => {
      createComponent({ isInvalid: true });

      expect(findListbox().props('variant')).toBe('danger');
    });

    it.each`
      name                        | subtitle                        | avatarUrl            | index
      ${TEST_GROUPS[0].full_name} | ${TEST_GROUPS[0].full_path}     | ${undefined}         | ${0}
      ${TEST_GROUPS[1].full_name} | ${TEST_GROUPS[1].full_path}     | ${TEST_GROUP_AVATAR} | ${1}
      ${TEST_USERS[0].name}       | ${`@${TEST_USERS[0].username}`} | ${TEST_USER_AVATAR}  | ${2}
      ${TEST_USERS[1].name}       | ${`@${TEST_USERS[1].username}`} | ${TEST_USER_AVATAR}  | ${3}
    `(
      'contains avatar with the correct props at index $index',
      async ({ name, subtitle, avatarUrl, index }) => {
        createComponent();
        openListbox();
        await waitForPromises();

        expect(findAvatar(index).props()).toMatchObject({
          label: name,
          subLabel: subtitle,
        });

        expect(findAvatar(index).attributes('src')).toBe(avatarUrl);
      },
    );

    describe('on show', () => {
      it('queries groups and users', async () => {
        createComponent();
        openListbox();
        await waitForPromises();

        expect(Api.groups).toHaveBeenCalledWith('', {
          skip_groups: [],
          all_available: false,
          order_by: 'id',
        });
        expect(Api.projectUsers).toHaveBeenCalledWith(TEST_PROJECT_ID, '', {
          skip_users: [],
        });

        expect(findListbox().props('items')).toMatchObject([...TEST_GROUPS, ...TEST_USERS]);
      });

      it('sets `searching` to `true` when first opening the dropdown', async () => {
        createComponent();

        expect(findListbox().props('searching')).toBe(false);

        openListbox();
        await nextTick();

        expect(findListbox().props('searching')).toBe(true);
      });
    });

    describe('on search', () => {
      it('sets `searching` to `true` while searching', async () => {
        createComponent();

        expect(findListbox().props('searching')).toBe(false);

        search('foo');
        await nextTick();

        expect(findListbox().props('searching')).toBe(true);
      });

      it('fetches groups and users matching the search string', async () => {
        const searchString = 'searchString';
        createComponent();

        search(searchString);
        await waitForPromises();

        expect(Api.groups).toHaveBeenCalledWith(searchString, {
          skip_groups: [],
          all_available: true,
          order_by: 'id',
        });
        expect(Api.projectUsers).toHaveBeenCalledWith(TEST_PROJECT_ID, searchString, {
          skip_users: [],
        });
      });

      describe.each`
        namespaceType              | api               | mockedValue             | expectedParams
        ${NAMESPACE_TYPES.PROJECT} | ${'projectUsers'} | ${TEST_USERS}           | ${[TEST_PROJECT_ID, TERM, { skip_users: [] }]}
        ${NAMESPACE_TYPES.GROUP}   | ${'groupMembers'} | ${{ data: TEST_USERS }} | ${[TEST_PROJECT_ID, { query: TERM, skip_users: [] }]}
      `(
        'with namespaceType: $namespaceType and search term',
        ({ namespaceType, api, mockedValue, expectedParams }) => {
          beforeEach(async () => {
            jest.spyOn(Api, api).mockReturnValue(Promise.resolve(mockedValue));

            createComponent({ namespaceType });
            await waitForPromises();

            search(TERM);
            await waitForPromises();
          });

          it('fetches all available groups', () => {
            expect(Api.groups).toHaveBeenCalledWith(TERM, {
              skip_groups: [],
              all_available: true,
              order_by: 'id',
            });
          });

          it('fetches users', () => {
            expect(Api[api]).toHaveBeenCalledWith(...expectedParams);
          });
        },
      );

      describe('with empty search term and skips', () => {
        const skipGroupIds = [7, 8];
        const skipUserIds = [9, 10];

        beforeEach(async () => {
          createComponent({
            skipGroupIds,
            skipUserIds,
          });
          openListbox();
          await waitForPromises();
        });

        it('skips groups and does not fetch all available', () => {
          expect(Api.groups).toHaveBeenCalledWith('', {
            skip_groups: skipGroupIds,
            all_available: false,
            order_by: 'id',
          });
        });

        it('skips users', () => {
          expect(Api.projectUsers).toHaveBeenCalledWith(TEST_PROJECT_ID, '', {
            skip_users: skipUserIds,
          });
        });
      });
    });

    describe('on selection', () => {
      it('emits input when data changes', async () => {
        const selectedUser = TEST_USERS[0];
        const selectedUserValue = `${TYPE_USER}.${selectedUser.id}`;

        createComponent();
        openListbox();
        await waitForPromises();

        expect(wrapper.emitted().input).toBeUndefined();

        findListbox().vm.$emit('select', selectedUserValue);

        const expected = {
          ...selectedUser,
          value: selectedUserValue,
          subtitle: `@${selectedUser.username}`,
        };

        expect(cloneDeep(wrapper.emitted().input)).toEqual([[[expected]]]);
      });
    });
  });
});
