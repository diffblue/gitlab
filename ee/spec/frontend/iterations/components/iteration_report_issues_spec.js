import {
  GlAlert,
  GlAvatar,
  GlBadge,
  GlButton,
  GlLabel,
  GlPagination,
  GlSkeletonLoader,
  GlTable,
} from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import IterationReportIssues from 'ee/iterations/components/iteration_report_issues.vue';
import { Namespace } from 'ee/iterations/constants';

describe('Iterations report issues', () => {
  let wrapper;
  const id = 3;
  const fullPath = 'gitlab-org';
  const label = {
    id: 17,
    title: 'Bug',
    color: '#123456',
    description: 'Bug label description',
    scoped: false,
  };
  const defaultProps = {
    fullPath,
    iterationId: `gid://gitlab/Iteration/${id}`,
  };

  const findGlBadge = () => wrapper.findComponent(GlBadge);
  const findGlButton = () => wrapper.findComponent(GlButton);
  const findGlLabel = () => wrapper.findComponent(GlLabel);
  const findGlSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findGlPagination = () => wrapper.findComponent(GlPagination);
  const findGlTable = () => wrapper.findComponent(GlTable);

  const mountComponent = ({
    props = defaultProps,
    loading = false,
    data = {},
    mountFunction = shallowMount,
  } = {}) => {
    wrapper = mountFunction(IterationReportIssues, {
      propsData: props,
      data() {
        return data;
      },
      mocks: {
        $apollo: {
          queries: { issues: { loading } },
        },
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('shows spinner while loading', () => {
    mountComponent({
      loading: true,
    });

    expect(findGlSkeletonLoader().exists()).toBe(true);
    expect(findGlTable().isVisible()).toBe(false);
  });

  it('shows iterations list when not loading', () => {
    mountComponent({ loading: false, mountFunction: mount });

    expect(findGlSkeletonLoader().isVisible()).toBe(false);
    expect(findGlTable().exists()).toBe(true);
    expect(wrapper.text()).toContain('No issues found');
  });

  it('shows error in a gl-alert', () => {
    const error = 'Oh no!';

    mountComponent({
      data: {
        error,
      },
    });

    expect(wrapper.findComponent(GlAlert).text()).toContain(error);
  });

  describe('with issues', () => {
    const pageSize = 20;
    const totalIssues = pageSize + 1;

    const assignees = Array(totalIssues)
      .fill(null)
      .map((_, i) => ({
        id: i,
        name: `User ${i}`,
        username: `user${i}`,
        state: 'active',
        avatarUrl: 'http://invalid/avatar.png',
        webUrl: `https://localhost:3000/user${i}`,
      }));

    const labels = Array(2)
      .fill(null)
      .map((_, i) => ({
        id: i,
        color: '#000',
        description: `Label ${i} description`,
        text_color: '#fff',
        title: `Label ${i}`,
      }));

    const issues = Array(totalIssues)
      .fill(null)
      .map((_, i) => ({
        id: i,
        title: `Issue ${i}`,
        assignees: assignees.slice(0, i),
        labels,
      }));

    const findIssues = () => wrapper.findAll('table tbody tr');
    const findAssigneesForIssue = (index) => findIssues().at(index).findAllComponents(GlAvatar);
    const findLabelsForIssue = (index) => findIssues().at(index).findAllComponents(GlLabel);

    describe('issue_list', () => {
      beforeEach(() => {
        const data = {
          issues: {
            list: issues,
            pageInfo: {
              hasNextPage: true,
              hasPreviousPage: false,
              startCursor: 'first-item',
              endCursor: 'last-item',
            },
            count: issues.length,
          },
        };

        mountComponent({ data, mountFunction: mount });
      });

      it('shows issue list in table', () => {
        expect(findGlTable().exists()).toBe(true);
        expect(findIssues()).toHaveLength(issues.length);
      });

      it('shows labels', () => {
        const labelsForFirstIssue = findLabelsForIssue(0);
        expect(labelsForFirstIssue).toHaveLength(2);
        expect(labelsForFirstIssue.at(0).props('title')).toBe(labels[0].title);
        expect(labelsForFirstIssue.at(1).props('title')).toBe(labels[1].title);
      });

      it('shows assignees', () => {
        expect(findAssigneesForIssue(0)).toHaveLength(0);
        expect(findAssigneesForIssue(1)).toHaveLength(1);
        expect(findAssigneesForIssue(10)).toHaveLength(10);
      });
    });

    describe('pagination', () => {
      beforeEach(() => {
        const data = {
          issues: {
            list: issues,
            pageInfo: {
              hasNextPage: true,
              hasPreviousPage: false,
              startCursor: 'first-item',
              endCursor: 'last-item',
            },
            count: issues.length,
          },
        };

        mountComponent({ data });
      });

      const findPagination = () => wrapper.findComponent(GlPagination);
      const setPage = (page) => {
        findPagination().vm.$emit('input', page);
        return findPagination().vm.$nextTick();
      };

      it('passes prev, next, and current page props', () => {
        expect(findPagination().exists()).toBe(true);
        expect(findPagination().props()).toMatchObject({
          value: wrapper.vm.pagination.currentPage,
          prevPage: wrapper.vm.prevPage,
          nextPage: wrapper.vm.nextPage,
        });
      });

      it('updates query variables when going to previous page', () => {
        return setPage(1).then(() => {
          expect(wrapper.vm.queryVariables).toEqual({
            beforeCursor: 'first-item',
            fullPath,
            id,
            lastPageSize: 20,
            isGroup: true,
          });
        });
      });

      it('updates query variables when going to next page', () => {
        return setPage(2).then(() => {
          expect(wrapper.vm.queryVariables).toEqual({
            afterCursor: 'last-item',
            fullPath,
            id,
            firstPageSize: 20,
            isGroup: true,
          });
        });
      });
    });
  });

  describe('IterationReportTabs query variables', () => {
    const expected = {
      afterCursor: undefined,
      firstPageSize: 20,
      fullPath: defaultProps.fullPath,
      id,
    };

    describe('when group', () => {
      it('has expected query variable values', () => {
        mountComponent({
          props: {
            ...defaultProps,
            namespaceType: Namespace.Group,
          },
        });

        expect(wrapper.vm.queryVariables).toEqual({
          ...expected,
          isGroup: true,
        });
      });
    });

    describe('when project', () => {
      it('has expected query variable values', () => {
        mountComponent({
          props: {
            ...defaultProps,
            namespaceType: Namespace.Project,
          },
        });

        expect(wrapper.vm.queryVariables).toEqual({
          ...expected,
          isGroup: false,
        });
      });
    });
  });

  describe('when a label is provided', () => {
    const count = 4;

    beforeEach(() => {
      mountComponent({
        props: { ...defaultProps, label },
        data: { issues: { count } },
      });
    });

    it('has section name which mentions the label', () => {
      expect(wrapper.find('section').attributes('aria-label')).toBe(
        `Issues with label ${label.title}`,
      );
    });

    it('shows button to expand/collapse the table', () => {
      expect(findGlButton().props('icon')).toBe('chevron-down');
      expect(findGlButton().attributes('aria-label')).toBe('Collapse issues');
    });

    it('shows label with the label title', () => {
      expect(findGlLabel().props()).toMatchObject({
        backgroundColor: label.color,
        description: label.description,
        showCloseButton: true,
        target: null,
        title: label.title,
      });
    });

    it('emits removeLabel event when label `x` is clicked', () => {
      findGlLabel().vm.$emit('close');

      expect(wrapper.emitted('removeLabel')).toEqual([[label.id]]);
    });

    it('shows badge with issue count', () => {
      expect(findGlBadge().text()).toBe(count.toString());
      expect(findGlBadge().attributes('aria-label')).toBe(`${count} issues`);
    });

    it('shows table with grey background', () => {
      expect(findGlTable().attributes('tbody-tr-class')).toBe('gl-bg-gray-10');
    });
  });

  describe('when a label is not provided', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('has section name which does not mention a label', () => {
      expect(wrapper.find('section').attributes('aria-label')).toBe('Issues');
    });

    it('hides button to expand/collapse the table', () => {
      expect(findGlButton().exists()).toBe(false);
    });

    it('hides label with the label title', () => {
      expect(findGlLabel().exists()).toBe(false);
    });

    it('hides badge with issue count', () => {
      expect(findGlBadge().exists()).toBe(false);
    });

    it('does not show table with grey background', () => {
      expect(findGlTable().attributes('tbody-tr-class')).toBeUndefined();
    });
  });

  describe('expand/collapse behaviour', () => {
    describe('when expanded', () => {
      beforeEach(() => {
        mountComponent({
          props: { ...defaultProps, label },
          data: { isExpanded: true },
        });
      });

      it('hides the issues when the `Collapse` button is clicked', async () => {
        expect(findGlButton().props('icon')).toBe('chevron-down');
        expect(findGlButton().attributes('aria-label')).toBe('Collapse issues');
        expect(findGlTable().isVisible()).toBe(true);
        expect(findGlPagination().isVisible()).toBe(true);

        await findGlButton().vm.$emit('click');

        expect(findGlButton().props('icon')).toBe('chevron-right');
        expect(findGlButton().attributes('aria-label')).toBe('Expand issues');
        expect(findGlTable().isVisible()).toBe(false);
        expect(findGlPagination().isVisible()).toBe(false);
      });
    });

    describe('when collapsed', () => {
      beforeEach(() => {
        mountComponent({
          props: { ...defaultProps, label },
          data: { isExpanded: false },
        });
      });

      it('shows the issues when the `Expand` button is clicked', async () => {
        expect(findGlButton().props('icon')).toBe('chevron-right');
        expect(findGlButton().attributes('aria-label')).toBe('Expand issues');
        expect(findGlTable().isVisible()).toBe(false);
        expect(findGlPagination().isVisible()).toBe(false);

        await findGlButton().vm.$emit('click');

        expect(findGlButton().props('icon')).toBe('chevron-down');
        expect(findGlButton().attributes('aria-label')).toBe('Collapse issues');
        expect(findGlTable().isVisible()).toBe(true);
        expect(findGlPagination().isVisible()).toBe(true);
      });
    });
  });
});
