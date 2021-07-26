import {
  GlPagination,
  GlDropdown,
  GlTable,
  GlAvatarLink,
  GlAvatarLabeled,
  GlSearchBoxByType,
  GlBadge,
  GlModal,
} from '@gitlab/ui';
import { mount, shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import SubscriptionSeats from 'ee/billings/seat_usage/components/subscription_seats.vue';
import { CANNOT_REMOVE_BILLABLE_MEMBER_MODAL_CONTENT } from 'ee/billings/seat_usage/constants';
import { mockDataSeats, mockTableItems } from 'ee_jest/billings/mock_data';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

const localVue = createLocalVue();
localVue.use(Vuex);

const actionSpies = {
  fetchBillableMembersList: jest.fn(),
  resetBillableMembers: jest.fn(),
  setBillableMemberToRemove: jest.fn(),
};

const providedFields = {
  namespaceName: 'Test Group Name',
  namespaceId: '1000',
};

const fakeStore = ({ initialState, initialGetters }) =>
  new Vuex.Store({
    actions: actionSpies,
    getters: {
      tableItems: () => mockTableItems,
      ...initialGetters,
    },
    state: {
      isLoading: false,
      hasError: false,
      namespaceId: null,
      members: [...mockDataSeats.data],
      total: 300,
      page: 1,
      perPage: 5,
      ...providedFields,
      ...initialState,
    },
  });

describe('Subscription Seats', () => {
  let wrapper;

  const createComponent = ({
    initialState = {},
    mountFn = shallowMount,
    initialGetters = {},
  } = {}) => {
    return extendedWrapper(
      mountFn(SubscriptionSeats, {
        store: fakeStore({ initialState, initialGetters }),
        localVue,
      }),
    );
  };

  const findTable = () => wrapper.find(GlTable);
  const findTableEmptyText = () => findTable().attributes('empty-text');

  const findPageHeading = () => wrapper.find('[data-testid="heading-info"]');
  const findPageHeadingText = () => findPageHeading().find('[data-testid="heading-info-text"]');
  const findPageHeadingBadge = () => findPageHeading().find(GlBadge);

  const findSearchBox = () => wrapper.find(GlSearchBoxByType);
  const findPagination = () => wrapper.find(GlPagination);

  const findAllRemoveUserItems = () => wrapper.findAllByTestId('remove-user');
  const findErrorModal = () => wrapper.findComponent(GlModal);

  const serializeUser = (rowWrapper) => {
    const avatarLink = rowWrapper.find(GlAvatarLink);
    const avatarLabeled = rowWrapper.find(GlAvatarLabeled);

    return {
      avatarLink: {
        href: avatarLink.attributes('href'),
        alt: avatarLink.attributes('alt'),
      },
      avatarLabeled: {
        src: avatarLabeled.attributes('src'),
        size: avatarLabeled.attributes('size'),
        text: avatarLabeled.text(),
      },
    };
  };

  const serializeTableRow = (rowWrapper) => {
    const emailWrapper = rowWrapper.find('[data-testid="email"]');

    return {
      user: serializeUser(rowWrapper),
      email: emailWrapper.text(),
      tooltip: emailWrapper.find('span').attributes('title'),
      dropdownExists: rowWrapper.find(GlDropdown).exists(),
    };
  };

  const findSerializedTable = (tableWrapper) => {
    return tableWrapper.findAll('tbody tr').wrappers.map(serializeTableRow);
  };

  describe('actions', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    afterEach(() => {
      wrapper.destroy();
    });

    it('correct actions are called on create', () => {
      expect(actionSpies.fetchBillableMembersList).toHaveBeenCalled();
    });
  });

  describe('renders', () => {
    beforeEach(() => {
      wrapper = createComponent({
        mountFn: mount,
        initialGetters: {
          tableItems: () => mockTableItems,
        },
      });
    });

    afterEach(() => {
      wrapper.destroy();
    });

    describe('heading text', () => {
      it('contains the group name and total seats number', () => {
        expect(findPageHeadingText().text()).toMatch(providedFields.namespaceName);
        expect(findPageHeadingBadge().text()).toMatch('300');
      });
    });

    describe('table content', () => {
      it('renders the correct data', () => {
        const serializedTable = findSerializedTable(findTable());

        expect(serializedTable).toMatchSnapshot();
      });
    });

    it('pagination is rendered and passed correct values', () => {
      const pagination = findPagination();

      expect(pagination.props()).toMatchObject({
        perPage: 5,
        totalItems: 300,
      });
    });

    describe('with error modal', () => {
      it('does not render the model if the user is not removable', async () => {
        await findAllRemoveUserItems().at(0).trigger('click');

        expect(findErrorModal().html()).toBe('');
      });

      it('renders the error modal if the user is removable', async () => {
        await findAllRemoveUserItems().at(2).trigger('click');

        expect(findErrorModal().text()).toContain(CANNOT_REMOVE_BILLABLE_MEMBER_MODAL_CONTENT);
      });
    });

    describe('members avatar', () => {
      it('shows the correct avatarLinks length', () => {
        const avatarLinks = findTable().findAllComponents(GlAvatarLink);
        expect(avatarLinks.length).toBe(4);
      });

      it.each(['group_invite', 'project_invite'])(
        'shows the correct badge for membership_type %s',
        (membershipType) => {
          const avatarLinks = findTable().findAllComponents(GlAvatarLink);
          const badgeText = (
            membershipType.charAt(0).toUpperCase() + membershipType.slice(1)
          ).replace('_', ' ');

          avatarLinks.wrappers.forEach((avatarLinkWrapper) => {
            const currentMember = mockTableItems.find(
              (item) => item.user.name === avatarLinkWrapper.attributes().alt,
            );

            if (membershipType === currentMember.user.membership_type) {
              expect(avatarLinkWrapper.find(GlBadge).text()).toBe(badgeText);
            }
          });
        },
      );
    });
  });

  describe('pagination', () => {
    it.each([null, NaN, undefined, 'a string', false])(
      'will not render given %s for currentPage',
      (value) => {
        wrapper = createComponent({
          initialState: {
            page: value,
          },
        });
        expect(findPagination().exists()).toBe(false);

        wrapper.destroy();
      },
    );
  });

  describe('is loading', () => {
    beforeEach(() => {
      wrapper = createComponent({ initialState: { isLoading: true } });
    });

    afterEach(() => {
      wrapper.destroy();
    });

    it('displays table in loading state', () => {
      expect(findTable().attributes('busy')).toBe('true');
    });
  });

  describe('search box', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('input event triggers the fetchBillableMembersList action', async () => {
      const SEARCH_STRING = 'search string';

      // fetchBillableMembersList is called once on created()
      expect(actionSpies.fetchBillableMembersList).toHaveBeenCalledTimes(1);

      await findSearchBox().vm.$emit('input', SEARCH_STRING);

      // fetchBillableMembersList is triggered a second time on input
      expect(actionSpies.fetchBillableMembersList).toHaveBeenCalledTimes(2);

      // fetchBillableMembersList is triggered the second time with the correct argument
      expect(actionSpies.fetchBillableMembersList.mock.calls[1][1]).toEqual({
        search: SEARCH_STRING,
      });
    });
  });

  describe('typing inside of the search box', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('causes the empty table text to change based on the number of typed characters', async () => {
      const EMPTY_TEXT_TOO_SHORT = 'Enter at least three characters to search.';
      const EMPTY_TEXT_NO_USERS = 'No users to display.';

      expect(findTableEmptyText()).toBe(EMPTY_TEXT_TOO_SHORT);

      await findSearchBox().vm.$emit('input', 'a');
      expect(findTableEmptyText()).toBe(EMPTY_TEXT_TOO_SHORT);

      await findSearchBox().vm.$emit('input', 'aa');
      expect(findTableEmptyText()).toBe(EMPTY_TEXT_TOO_SHORT);

      await findSearchBox().vm.$emit('input', 'aaa');
      expect(findTableEmptyText()).toBe(EMPTY_TEXT_NO_USERS);
    });

    it('dispatches the.resetBillableMembers action when 1 or 2 characters have been typed', async () => {
      expect(actionSpies.resetBillableMembers).not.toHaveBeenCalled();

      await findSearchBox().vm.$emit('input', 'a');
      expect(actionSpies.resetBillableMembers).toHaveBeenCalledTimes(1);

      await findSearchBox().vm.$emit('input', 'aa');
      expect(actionSpies.resetBillableMembers).toHaveBeenCalledTimes(2);

      await findSearchBox().vm.$emit('input', 'aaa');
      expect(actionSpies.resetBillableMembers).toHaveBeenCalledTimes(2);
    });

    it('dispatches fetchBillableMembersList action when search box is emptied out', async () => {
      expect(actionSpies.fetchBillableMembersList).toHaveBeenCalledTimes(1);

      await findSearchBox().vm.$emit('input', 'a');
      expect(actionSpies.fetchBillableMembersList).toHaveBeenCalledTimes(1);

      await findSearchBox().vm.$emit('input', '');
      expect(actionSpies.fetchBillableMembersList).toHaveBeenCalledTimes(2);
    });

    it('dispatches fetchBillableMembersList action when more than 2 characters are typed', async () => {
      expect(actionSpies.fetchBillableMembersList).toHaveBeenCalledTimes(1);

      await findSearchBox().vm.$emit('input', 'a');
      expect(actionSpies.fetchBillableMembersList).toHaveBeenCalledTimes(1);

      await findSearchBox().vm.$emit('input', 'aa');
      expect(actionSpies.fetchBillableMembersList).toHaveBeenCalledTimes(1);

      await findSearchBox().vm.$emit('input', 'aaa');
      expect(actionSpies.fetchBillableMembersList).toHaveBeenCalledTimes(2);

      await findSearchBox().vm.$emit('input', 'aaaa');
      expect(actionSpies.fetchBillableMembersList).toHaveBeenCalledTimes(3);
    });
  });
});
