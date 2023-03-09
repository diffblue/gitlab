import { shallowMount } from '@vue/test-utils';
import Assignee from 'ee/external_issues_show/components/sidebar/assignee.vue';
import IssueDueDate from 'ee/external_issues_show/components/sidebar/issue_due_date.vue';
import IssueField from 'ee/external_issues_show/components/sidebar/issue_field.vue';
import Sidebar from 'ee/integrations/zentao/issues_show/components/sidebar/zentao_issues_sidebar_root.vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import LabelsSelect from '~/sidebar/components/labels/labels_select_vue/labels_select_root.vue';
import { mockZentaoIssue as mockZentaoIssueData } from '../../mock_data';

const mockZentaoIssue = convertObjectPropsToCamelCase(mockZentaoIssueData, { deep: true });

describe('ZentaoIssuesSidebar', () => {
  let wrapper;

  const defaultProps = {
    sidebarExpanded: false,
    issue: mockZentaoIssue,
  };

  const createComponent = () => {
    wrapper = shallowMount(Sidebar, {
      propsData: defaultProps,
    });
  };

  beforeEach(() => {
    createComponent();
  });

  const findLabelsSelect = () => wrapper.findComponent(LabelsSelect);
  const findAssignee = () => wrapper.findComponent(Assignee);
  const findIssueDueDate = () => wrapper.findComponent(IssueDueDate);
  const findIssueField = () => wrapper.findComponent(IssueField);

  it('renders Labels block', () => {
    expect(findLabelsSelect().props('selectedLabels')).toBe(mockZentaoIssue.labels);
  });

  it('renders Assignee block', () => {
    const assignee = findAssignee();

    expect(assignee.props('assignee')).toBe(mockZentaoIssue.assignees[0]);
    expect(assignee.props('avatarSubLabel')).toBe('ZenTao user');
  });

  it('renders IssueDueDate', () => {
    const dueDate = findIssueDueDate();

    expect(dueDate.props('dueDate')).toBe(mockZentaoIssue.dueDate);
  });

  it('renders IssueField', () => {
    const field = findIssueField();

    expect(field.props('icon')).toBe('progress');
    expect(field.props('title')).toBe('Status');
    expect(field.props('value')).toBe(mockZentaoIssue.status);
  });
});
