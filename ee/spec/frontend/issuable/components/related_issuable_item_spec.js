import { mount } from '@vue/test-utils';
import IssueWeight from 'ee_component/boards/components/issue_card_weight.vue';
import { TEST_HOST } from 'helpers/test_constants';
import {
  defaultAssignees,
  defaultMilestone,
} from 'jest/issuable/components/related_issuable_mock_data';
import RelatedIssuableItem from '~/issuable/components/related_issuable_item.vue';

describe('RelatedIssuableItem', () => {
  let wrapper;

  function mountComponent({ mountMethod = mount, stubs = {}, props = {}, slots = {} } = {}) {
    wrapper = mountMethod(RelatedIssuableItem, {
      propsData: props,
      provide: {
        reportAbusePath: '/report/abuse/path',
      },
      slots,
      stubs,
    });
  }

  const props = {
    idKey: 1,
    displayReference: 'gitlab-org/gitlab-test#1',
    pathIdSeparator: '#',
    path: `${TEST_HOST}/path`,
    title: 'title',
    confidential: true,
    dueDate: '1990-12-31',
    weight: 10,
    createdAt: '2018-12-01T00:00:00.00Z',
    milestone: defaultMilestone,
    assignees: defaultAssignees,
    eventNamespace: 'relatedIssue',
  };
  const slots = {
    dueDate: '<div class="js-due-date-slot"></div>',
    weight: '<div class="js-weight-slot"></div>',
  };

  beforeEach(() => {
    mountComponent({ props, slots });
  });

  it('renders weight component with correct weight', () => {
    expect(wrapper.findComponent(IssueWeight).props('weight')).toBe(props.weight);
  });
});
