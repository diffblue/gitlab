import { GlEmptyState, GlSprintf, GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import { nextTick } from 'vue';
import ExternalIssuesListEmptyState from 'ee/external_issues_list/components/external_issues_list_empty_state.vue';
import { externalIssuesListEmptyStateI18n } from 'ee/external_issues_list/constants';
import { STATUS_ALL, STATUS_CLOSED, STATUS_OPEN } from '~/issues/constants';

import { mockProvide } from '../mock_data';

const createComponent = (props = {}) =>
  shallowMount(ExternalIssuesListEmptyState, {
    provide: mockProvide,
    propsData: {
      currentState: 'opened',
      issuesCount: {
        [STATUS_OPEN]: 0,
        [STATUS_CLOSED]: 0,
        [STATUS_ALL]: 0,
      },
      hasFiltersApplied: false,
      ...props,
    },
    stubs: { GlEmptyState },
  });

describe('ExternalIssuesListEmptyState', () => {
  let wrapper;

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);

  beforeEach(() => {
    wrapper = createComponent();
  });

  describe('computed', () => {
    describe('hasIssues', () => {
      it('returns false when total of opened and closed issues within `issuesCount` is 0', () => {
        expect(wrapper.vm.hasIssues).toBe(false);
      });

      it('returns true when total of opened and closed issues within `issuesCount` is more than 0', async () => {
        wrapper.setProps({
          issuesCount: {
            [STATUS_OPEN]: 1,
            [STATUS_CLOSED]: 1,
          },
        });

        await nextTick();

        expect(wrapper.vm.hasIssues).toBe(true);
      });
    });

    describe('emptyStateTitle', () => {
      it(`returns correct string when hasFiltersApplied prop is true`, async () => {
        wrapper.setProps({
          hasFiltersApplied: true,
        });

        await nextTick();

        expect(findEmptyState().props('title')).toBe(
          externalIssuesListEmptyStateI18n.titleWhenFilters,
        );
      });

      it(`returns correct string when hasFiltersApplied prop is false and hasIssues is true`, async () => {
        wrapper.setProps({
          hasFiltersApplied: false,
          issuesCount: {
            [STATUS_OPEN]: 1,
            [STATUS_CLOSED]: 1,
          },
        });

        await nextTick();

        expect(findEmptyState().props('title')).toBe(
          externalIssuesListEmptyStateI18n.filterStateEmptyMessage[STATUS_OPEN],
        );
      });

      it('returns default title string when both hasFiltersApplied and hasIssues props are false', async () => {
        wrapper.setProps({
          hasFiltersApplied: false,
        });

        await nextTick();

        expect(findEmptyState().props('title')).toBe(mockProvide.emptyStateNoIssueText);
      });
    });

    describe('emptyStateDescription', () => {
      it(`returns correct when hasFiltersApplied prop is true`, async () => {
        wrapper.setProps({
          hasFiltersApplied: true,
        });

        await nextTick();

        expect(wrapper.vm.emptyStateDescription).toBe(
          externalIssuesListEmptyStateI18n.descriptionWhenFilters,
        );
      });

      it(`returns correct string when both hasFiltersApplied and hasIssues props are false`, async () => {
        wrapper.setProps({
          hasFiltersApplied: false,
        });

        await nextTick();

        expect(wrapper.vm.emptyStateDescription).toBe(
          externalIssuesListEmptyStateI18n.descriptionWhenNoIssues,
        );
      });

      it(`returns empty string when hasFiltersApplied is false and hasIssues is true`, async () => {
        wrapper.setProps({
          hasFiltersApplied: false,
          issuesCount: {
            [STATUS_OPEN]: 1,
            [STATUS_CLOSED]: 1,
          },
        });

        await nextTick();

        expect(wrapper.vm.emptyStateDescription).toBe('');
      });
    });
  });

  describe('template', () => {
    it('renders gl-empty-state component', () => {
      expect(wrapper.findComponent(GlEmptyState).exists()).toBe(true);
    });

    it('renders empty state title', async () => {
      const emptyStateEl = wrapper.findComponent(GlEmptyState);

      expect(emptyStateEl.props()).toMatchObject({
        svgPath: mockProvide.emptyStatePath,
        title: mockProvide.emptyStateNoIssueText,
      });

      wrapper.setProps({
        hasFiltersApplied: true,
      });

      await nextTick();

      expect(emptyStateEl.props('title')).toBe(externalIssuesListEmptyStateI18n.titleWhenFilters);

      wrapper.setProps({
        hasFiltersApplied: false,
        issuesCount: {
          [STATUS_OPEN]: 1,
          [STATUS_CLOSED]: 1,
        },
      });

      await nextTick();

      expect(emptyStateEl.props('title')).toBe(
        externalIssuesListEmptyStateI18n.filterStateEmptyMessage[STATUS_OPEN],
      );
    });

    it('renders empty state description', () => {
      const descriptionEl = wrapper.findComponent(GlSprintf);

      expect(descriptionEl.exists()).toBe(true);
      expect(descriptionEl.attributes('message')).toBe(
        'To keep this project going, create a new issue.',
      );
    });

    it('does not render empty state description when issues are present', async () => {
      wrapper.setProps({
        issuesCount: {
          [STATUS_OPEN]: 1,
          [STATUS_CLOSED]: 1,
        },
      });

      await nextTick();

      const descriptionEl = wrapper.findComponent(GlSprintf);

      expect(descriptionEl.exists()).toBe(false);
    });

    it('renders "create issue button', () => {
      const buttonEl = wrapper.findComponent(GlButton);

      expect(buttonEl.exists()).toBe(true);
      expect(buttonEl.attributes('href')).toBe(mockProvide.issueCreateUrl);
      expect(buttonEl.text()).toBe(mockProvide.createNewIssueText);
    });
  });
});
