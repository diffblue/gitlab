import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlIcon, GlSkeletonLoader } from '@gitlab/ui';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

import StatusBox from '~/issuable/components/status_box.vue';
import epicQuery from 'ee/issuable/popover/queries/epic.query.graphql';
import EpicPopover from 'ee/issuable/popover/components/epic_popover.vue';

describe('Epic Popover', () => {
  const mockEpicResponse = {
    data: {
      group: {
        id: 'gid://gitlab/Group/1',
        epic: {
          id: 'gid://gitlab/Epic/1',
          iid: '1',
          title: 'Maxime ut soluta cumque est labore id dicta atque.',
          state: 'opened',
          createdAt: '2022-10-11',
          confidential: false,
          reference: '&1',
          startDate: '2022-10-31',
          dueDate: '2023-09-30',
          __typename: 'Epic',
        },
        __typename: 'Group',
      },
    },
  };
  const mockEpic = mockEpicResponse.data.group.epic;
  let wrapper;

  Vue.use(VueApollo);

  const mountComponent = ({
    queryResponse = jest.fn().mockResolvedValue(mockEpicResponse),
  } = {}) => {
    wrapper = shallowMountExtended(EpicPopover, {
      apolloProvider: createMockApollo([[epicQuery, queryResponse]]),
      propsData: {
        target: document.createElement('a'),
        namespacePath: 'gitlab-org',
        iid: '1',
        cachedTitle: 'Maxime ut soluta cumque est labore id dicta atque.',
      },
    });
  };

  const findStatusBox = () => wrapper.findComponent(StatusBox);

  describe('while popover is loading', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('shows skeleton-loader', () => {
      expect(wrapper.findComponent(GlSkeletonLoader).exists()).toBe(true);
    });

    it('does not show status-box or created timestamp', () => {
      expect(findStatusBox().exists()).toBe(false);
      expect(wrapper.findByTestId('created-at').exists()).toBe(false);
    });

    it('does not show epic title', () => {
      expect(wrapper.find('h5').exists()).toBe(false);
    });

    it('shows epic reference', () => {
      expect(wrapper.text()).toContain(`gitlab-org&${mockEpic.iid}`);
    });
  });

  describe('when popover contents are loaded', () => {
    beforeEach(async () => {
      mountComponent();

      await waitForPromises();
    });

    it('shows status-box', () => {
      const statusBox = findStatusBox();
      expect(statusBox.exists()).toBe(true);
      expect(statusBox.props()).toEqual({
        issuableType: 'epic',
        initialState: mockEpic.state,
      });
    });

    it('shows confidentiality icon when epic is confidential', async () => {
      mountComponent({
        queryResponse: jest.fn().mockResolvedValue({
          data: {
            group: {
              id: 'gid://gitlab/Group/1',
              __typename: 'Group',
              epic: {
                ...mockEpic,
                confidential: true,
              },
            },
          },
        }),
      });

      await waitForPromises();

      const confidentialIcon = wrapper.findByTestId('confidential-icon');
      expect(confidentialIcon.exists()).toBe(true);
      expect(confidentialIcon.props()).toEqual({
        ariaLabel: 'Confidential',
        size: 16,
        name: 'eye-slash',
      });
    });

    it('shows created timestamp', () => {
      const createdAt = wrapper.findByTestId('created-at');
      expect(createdAt.exists()).toBe(true);
      expect(createdAt.text()).toContain('Opened');
    });

    it('shows epic title and reference', () => {
      const title = wrapper.find('h5');
      expect(title.exists()).toBe(true);
      expect(title.text()).toBe(mockEpic.title);
      expect(wrapper.text()).toContain(`gitlab-org${mockEpic.reference}`);
    });

    it('shows epic timeframe', () => {
      const timeframe = wrapper.findByTestId('epic-timeframe');
      expect(timeframe.exists()).toBe(true);
      expect(timeframe.findComponent(GlIcon).exists()).toBe(true);
      expect(timeframe.text()).toBe('Oct 31, 2022 – Sep 30, 2023');
    });
  });
});
