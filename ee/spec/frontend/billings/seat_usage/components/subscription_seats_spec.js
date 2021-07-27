import {
  GlPagination,
  GlDropdown,
  GlTable,
  GlAvatarLink,
  GlAvatarLabeled,
  GlBadge,
  GlModal,
} from '@gitlab/ui';
import { mount, shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import SubscriptionSeats from 'ee/billings/seat_usage/components/subscription_seats.vue';
import { CANNOT_REMOVE_BILLABLE_MEMBER_MODAL_CONTENT } from 'ee/billings/seat_usage/constants';
import { mockDataSeats, mockTableItems } from 'ee_jest/billings/mock_data';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import FilterSortContainerRoot from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

const actionSpies = {
  fetchBillableMembersList: jest.fn(),
  resetBillableMembers: jest.fn(),
  setBillableMemberToRemove: jest.fn(),
  setSearchQuery: jest.fn(),
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
      namespaceId: 1,
      members: [...mockDataSeats.data],
      total: 300,
      page: 1,
      perPage: 5,
      sort: 'last_activity_on_desc',
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

  const findTable = () => wrapper.findComponent(GlTable);

  const findPageHeading = () => wrapper.find('[data-testid="heading-info"]');
  const findPageHeadingText = () => findPageHeading().find('[data-testid="heading-info-text"]');
  const findPageHeadingBadge = () => findPageHeading().find(GlBadge);

  const findSearchBox = () => wrapper.findComponent(FilterSortContainerRoot);
  const findPagination = () => wrapper.findComponent(GlPagination);

  const findAllRemoveUserItems = () => wrapper.findAllByTestId('remove-user');
  const findErrorModal = () => wrapper.findComponent(GlModal);

  const serializeUser = (rowWrapper) => {
    const avatarLink = rowWrapper.findComponent(GlAvatarLink);
    const avatarLabeled = rowWrapper.findComponent(GlAvatarLabeled);

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
      dropdownExists: rowWrapper.findComponent(GlDropdown).exists(),
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

    it('input event triggers the setSearchQuery action', async () => {
      const SEARCH_STRING = 'search string';

      // fetchBillableMembersList is called once on created()
      expect(actionSpies.fetchBillableMembersList).toHaveBeenCalledTimes(1);

      await findSearchBox().vm.$emit('onFilter', [
        { type: 'filtered-search-term', value: { data: SEARCH_STRING } },
      ]);

      expect(actionSpies.setSearchQuery).toHaveBeenCalledWith(expect.any(Object), SEARCH_STRING);
    });
  });
});
