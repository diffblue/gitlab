import { GlPagination, GlBadge, GlAvatarLabeled, GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import { mockDataMembers, mockInvitedApprovedMember } from 'ee_jest/pending_members/mock_data';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import PendingMembersApp from 'ee/pending_members/components/app.vue';
import { PENDING_MEMBERS_TITLE, LABEL_APPROVE_ALL } from 'ee/pending_members/constants';

Vue.use(Vuex);

const actionSpies = {
  fetchPendingMembersList: jest.fn(),
};

const providedFields = {
  namespaceId: '1000',
  namespaceName: 'Test Group Name',
};

const fakeStore = ({ initialState, initialGetters }) =>
  new Vuex.Store({
    actions: actionSpies,
    getters: {
      tableItems: () => mockDataMembers.data,
      ...initialGetters,
    },
    state: {
      isLoading: false,
      hasError: false,
      namespaceId: 1,
      members: mockDataMembers.data,
      total: 300,
      page: 1,
      perPage: 5,
      ...providedFields,
      ...initialState,
    },
  });

describe('PendingMembersApp', () => {
  let wrapper;

  const createComponent = ({ initialState = {}, initialGetters = {}, stubs = {} } = {}) => {
    wrapper = extendedWrapper(
      shallowMount(PendingMembersApp, {
        store: fakeStore({ initialState, initialGetters }),
        stubs,
      }),
    );
  };

  const findMemberRows = () => wrapper.findAllByTestId('pending-members-row');
  const findPagination = () => wrapper.findComponent(GlPagination);

  beforeEach(() => {
    createComponent();
  });

  it('renders page title', () => {
    expect(wrapper.find('h1').text()).toBe(PENDING_MEMBERS_TITLE);
  });

  it('renders approve all button', () => {
    const approveAllButton = wrapper.findByTestId('approve-all-button');
    expect(approveAllButton.text()).toBe(LABEL_APPROVE_ALL);
  });

  describe('approve all members modal', () => {
    const findApproveAllModal = () => wrapper.findByTestId('approve-all-modal');

    describe('when user cap is not set', () => {
      beforeEach(() => {
        createComponent({ stubs: { GlModal } });
      });

      it('passes correct text to modal', () => {
        expect(findApproveAllModal().props('title')).toBe('Approve 300 pending members');
        expect(findApproveAllModal().text()).toContain(
          'Approved members will use an additional 300 seats in your subscription.',
        );
      });
    });

    describe('when user cap is set', () => {
      beforeEach(() => {
        createComponent({ initialState: { userCapSet: true }, stubs: { GlModal } });
      });

      it('passes correct text to modal', () => {
        expect(findApproveAllModal().props('title')).toBe('Approve 300 pending members');
        expect(findApproveAllModal().text()).toContain(
          'Approved members will use an additional 300 seats in your subscription, which may override your user cap.',
        );
      });
    });
  });

  it('renders pending members', () => {
    const memberRows = findMemberRows();

    expect(memberRows.length).toBe(mockDataMembers.data.length);
    expect(findMemberRows().wrappers.map((w) => w.html())).toMatchSnapshot();
  });

  it('pagination is rendered and passed correct values', () => {
    const pagination = findPagination();

    expect(pagination.props()).toMatchObject({
      perPage: 5,
      totalItems: 300,
    });
  });

  it('render badge for approved invited members', () => {
    createComponent({
      stubs: { GlBadge, GlAvatarLabeled },
      initialGetters: { tableItems: () => [mockInvitedApprovedMember] },
      initialState: { members: [mockInvitedApprovedMember] },
    });
    expect(wrapper.findComponent(GlBadge).text()).toEqual('Awaiting member signup');
  });
});
