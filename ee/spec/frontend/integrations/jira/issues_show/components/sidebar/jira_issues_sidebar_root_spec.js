import { shallowMount } from '@vue/test-utils';

import Assignee from 'ee/external_issues_show/components/sidebar/assignee.vue';
import IssueDueDate from 'ee/external_issues_show/components/sidebar/issue_due_date.vue';
import IssueField from 'ee/external_issues_show/components/sidebar/issue_field.vue';
import Sidebar from 'ee/integrations/jira/issues_show/components/sidebar/jira_issues_sidebar_root.vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import CopyableField from '~/sidebar/components/copy/copyable_field.vue';
import LabelsSelect from '~/sidebar/components/labels/labels_select_vue/labels_select_root.vue';
import { mockJiraIssue as mockJiraIssueData } from '../../mock_data';

const mockJiraIssue = convertObjectPropsToCamelCase(mockJiraIssueData, { deep: true });

describe('JiraIssuesSidebar', () => {
  let wrapper;

  const defaultProps = {
    sidebarExpanded: false,
    issue: mockJiraIssue,
  };

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMount(Sidebar, {
      propsData: { ...defaultProps, ...props },
    });
  };

  const findLabelsSelect = () => wrapper.findComponent(LabelsSelect);
  const findAssignee = () => wrapper.findComponent(Assignee);
  const findIssueDueDate = () => wrapper.findComponent(IssueDueDate);
  const findIssueField = () => wrapper.findComponent(IssueField);
  const findCopyableField = () => wrapper.findComponent(CopyableField);

  it('renders Labels block', () => {
    createComponent();

    expect(findLabelsSelect().props('selectedLabels')).toBe(mockJiraIssue.labels);
  });

  it('renders Assignee block', () => {
    createComponent();
    const assignee = findAssignee();

    expect(assignee.props('assignee')).toBe(mockJiraIssue.assignees[0]);
    expect(assignee.props('avatarSubLabel')).toBe('Jira user');
  });

  it('renders IssueDueDate', () => {
    createComponent();
    const dueDate = findIssueDueDate();

    expect(dueDate.props('dueDate')).toBe(mockJiraIssue.dueDate);
  });

  it('renders IssueField', () => {
    createComponent();
    const field = findIssueField();

    expect(field.props('icon')).toBe('progress');
    expect(field.props('title')).toBe('Status');
    expect(field.props('value')).toBe(mockJiraIssue.status);
  });

  describe('when references.relative is null', () => {
    it('does not render issue reference', () => {
      createComponent({
        props: {
          issue: {
            references: {},
          },
        },
      });

      expect(findCopyableField().exists()).toBe(false);
    });
  });

  describe('when references.relative is provided', () => {
    it('renders issue reference', () => {
      createComponent();
      const issueReference = findCopyableField();

      expect(issueReference.exists()).toBe(true);
      expect(issueReference.props('value')).toBe(defaultProps.issue.references.relative);
    });
  });
});
