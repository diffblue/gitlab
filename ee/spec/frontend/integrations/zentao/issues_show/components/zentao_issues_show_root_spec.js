import { GlAlert, GlLoadingIcon, GlBadge } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import { STATUS_CLOSED, STATUS_OPEN } from '~/issues/constants';
import ZentaoIssuesShow from 'ee/integrations/zentao/issues_show/components/zentao_issues_show_root.vue';

import waitForPromises from 'helpers/wait_for_promises';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import IssuableHeader from '~/vue_shared/issuable/show/components/issuable_header.vue';
import IssuableShow from '~/vue_shared/issuable/show/components/issuable_show_root.vue';
import IssuableDiscussion from '~/vue_shared/issuable/show/components/issuable_discussion.vue';
import Note from 'ee/external_issues_show/components/note.vue';
import IssuableSidebar from '~/vue_shared/issuable/sidebar/components/issuable_sidebar_root.vue';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';

import { mockZentaoIssue, mockZentaoIssueComment } from '../mock_data';

const mockZentaoIssuesShowPath = 'zentao_issues_show_path';

describe('ZentaoIssuesShow', () => {
  let wrapper;
  let mockAxios;

  const findGlAlert = () => wrapper.findComponent(GlAlert);
  const findGlLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findIssuableShow = () => wrapper.findComponent(IssuableShow);
  const findIssuableShowStatusBadge = () =>
    wrapper.findComponent(IssuableHeader).findComponent(GlBadge);

  const createComponent = () => {
    wrapper = shallowMountExtended(ZentaoIssuesShow, {
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      stubs: {
        IssuableHeader,
        IssuableShow,
        IssuableSidebar,
        IssuableDiscussion,
        Note,
        GlBadge,
      },
      provide: {
        issuesShowPath: mockZentaoIssuesShowPath,
      },
    });
  };

  beforeEach(() => {
    mockAxios = new MockAdapter(axios);
  });

  afterEach(() => {
    mockAxios.restore();
  });

  describe('when issue is loading', () => {
    it('renders GlLoadingIcon', () => {
      createComponent();

      expect(findGlLoadingIcon().exists()).toBe(true);
      expect(findGlAlert().exists()).toBe(false);
      expect(findIssuableShow().exists()).toBe(false);
    });
  });

  describe('when error occurs during fetch', () => {
    it('renders error message', async () => {
      mockAxios.onGet(mockZentaoIssuesShowPath).replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);
      createComponent();

      await waitForPromises();

      const alert = findGlAlert();

      expect(findGlLoadingIcon().exists()).toBe(false);
      expect(alert.exists()).toBe(true);
      expect(alert.text()).toBe(ZentaoIssuesShow.i18n.defaultErrorMessage);
      expect(alert.props('variant')).toBe('danger');
      expect(findIssuableShow().exists()).toBe(false);
    });
  });

  it('renders IssuableShow', async () => {
    mockAxios.onGet(mockZentaoIssuesShowPath).replyOnce(HTTP_STATUS_OK, mockZentaoIssue);
    createComponent();

    await waitForPromises();

    expect(findGlLoadingIcon().exists()).toBe(false);
    expect(findIssuableShow().exists()).toBe(true);
  });

  it('displays a tooltip', async () => {
    mockAxios.onGet(mockZentaoIssuesShowPath).replyOnce(HTTP_STATUS_OK, {
      ...mockZentaoIssue,
      comments: [mockZentaoIssueComment],
    });
    createComponent();

    await waitForPromises();
    const issuableDiscussion = wrapper.findComponent(IssuableDiscussion).findComponent(GlBadge);
    const tooltip = getBinding(issuableDiscussion.element, 'gl-tooltip');
    expect(tooltip).toBeDefined();
    expect(tooltip.value).toEqual({ title: 'This is a ZenTao user.' });
  });

  describe.each`
    state            | statusIcon              | badgeText
    ${STATUS_OPEN}   | ${'issue-open-m'}       | ${'Open'}
    ${STATUS_CLOSED} | ${'mobile-issue-close'} | ${'Closed'}
  `('when issue state is `$state`', ({ state, statusIcon, badgeText }) => {
    beforeEach(async () => {
      mockAxios
        .onGet(mockZentaoIssuesShowPath)
        .replyOnce(HTTP_STATUS_OK, { ...mockZentaoIssue, state });
      createComponent();

      await waitForPromises();
    });

    it('sets `statusIcon` prop correctly', () => {
      expect(findIssuableShow().props('statusIcon')).toBe(statusIcon);
    });

    it('renders correct status badge text', () => {
      expect(findIssuableShowStatusBadge().text()).toBe(badgeText);
    });
  });
});
