import { shallowMount } from '@vue/test-utils';
import $ from 'jquery';
import 'select2/select2';
import Api from 'ee/api';
import ApproversSelect from 'ee/approvals/components/approvers_select.vue';
import { TYPE_USER, TYPE_GROUP } from 'ee/approvals/constants';
import { TEST_HOST } from 'helpers/test_constants';
import waitForPromises from 'helpers/wait_for_promises';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';

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

const waitForEvent = ($input, event) =>
  new Promise((resolve) => {
    $input.one(event, resolve);
  });
const parseAvatar = (element) =>
  element.classList.contains('identicon') ? null : element.getAttribute('src');
const select2Container = () => document.querySelector('.select2-container');
const select2DropdownOptions = () => document.querySelectorAll('#select2-drop .user-result');
const select2DropdownItems = () =>
  Array.prototype.map.call(select2DropdownOptions(), (element) => {
    const isGroup = element.classList.contains('group-result');
    const avatar = parseAvatar(element.querySelector('.avatar'));

    return isGroup
      ? {
          avatar_url: avatar,
          full_name: element.querySelector('.group-name').textContent,
          full_path: element.querySelector('.group-path').textContent,
        }
      : {
          avatar_url: avatar,
          name: element.querySelector('.user-name').textContent,
          username: element.querySelector('.user-username').textContent,
        };
  });

describe('Approvals ApproversSelect', () => {
  let wrapper;
  let $input;

  const factory = async (options = {}) => {
    const propsData = {
      namespaceId: TEST_PROJECT_ID,
      ...options.propsData,
    };

    wrapper = await shallowMount(ApproversSelect, {
      ...options,
      propsData,
      attachTo: document.body,
      provide: {
        ...options.provide,
      },
    });

    await waitForPromises();

    $input = $(wrapper.vm.$refs.input);
  };

  const search = (term = '') => {
    $input.select2('search', term);
    jest.runOnlyPendingTimers();
  };

  beforeEach(() => {
    jest.spyOn(Api, 'groups').mockResolvedValue(TEST_GROUPS);
    jest.spyOn(Api, 'projectGroups').mockResolvedValue(TEST_GROUPS);
    jest.spyOn(Api, 'projectUsers').mockReturnValue(Promise.resolve(TEST_USERS));
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders select2 input', async () => {
    expect(select2Container()).toBe(null);

    await factory();

    expect(select2Container()).not.toBe(null);
  });

  it('queries and displays groups and users', async () => {
    await factory();

    const expected = TEST_GROUPS.concat(TEST_USERS)
      .map(({ id, ...obj }) => obj)
      .map(({ username, ...obj }) => (!username ? obj : { ...obj, username: `@${username}` }));

    search();

    await waitForEvent($input, 'select2-loaded');
    const items = select2DropdownItems();

    expect(items).toEqual(expected);
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
        await factory({ propsData: { namespaceType } });

        search(TERM);

        await waitForEvent($input, 'select2-loaded');
      });

      it('fetches all available groups', () => {
        expect(Api.groups).toHaveBeenCalledWith(TERM, {
          skip_groups: [],
          all_available: true,
        });
      });

      it('fetches users', () => {
        expect(Api[api]).toHaveBeenCalledWith(...expectedParams);
      });
    },
  );

  describe('with permitAllSharedGroupsForApproval', () => {
    beforeEach(async () => {
      await factory({
        provide: {
          glFeatures: {
            permitAllSharedGroupsForApproval: true,
          },
        },
      });
    });

    it('fetches all available groups including non-visible shared groups', async () => {
      search();

      await waitForEvent($input, 'select2-loaded');

      expect(Api.projectGroups).toHaveBeenCalledWith(TEST_PROJECT_ID, {
        skip_groups: [],
        with_shared: true,
        shared_visible_only: false,
        shared_min_access_level: 30,
      });
    });
  });

  describe('with empty seach term and skips', () => {
    const skipGroupIds = [7, 8];
    const skipUserIds = [9, 10];

    beforeEach(async () => {
      await factory({
        propsData: {
          skipGroupIds,
          skipUserIds,
        },
      });

      search();

      await waitForEvent($input, 'select2-loaded');
      jest.runOnlyPendingTimers();
    });

    it('skips groups and does not fetch all available', () => {
      expect(Api.groups).toHaveBeenCalledWith('', {
        skip_groups: skipGroupIds,
        all_available: false,
      });
    });

    it('skips users', () => {
      expect(Api.projectUsers).toHaveBeenCalledWith(TEST_PROJECT_ID, '', {
        skip_users: skipUserIds,
      });
    });
  });

  it('emits input when data changes', async () => {
    await factory();

    const expectedFinal = [
      { ...TEST_USERS[0], type: TYPE_USER },
      { ...TEST_GROUPS[0], type: TYPE_GROUP },
    ];
    const expected = expectedFinal.map((x, idx) => [expectedFinal.slice(0, idx + 1)]);

    search();

    await waitForPromises();
    const options = select2DropdownOptions();
    $(options[TEST_GROUPS.length]).trigger('mouseup');
    $(options[0]).trigger('mouseup');

    await waitForPromises();
    expect(wrapper.emitted().input).toEqual(expected);
  });
});
