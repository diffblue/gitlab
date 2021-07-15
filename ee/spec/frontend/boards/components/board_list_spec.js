import BoardNewEpic from 'ee/boards/components/board_new_epic.vue';
import createComponent from 'jest/boards/board_list_helper';

import BoardCard from '~/boards/components/board_card.vue';
import BoardCardInner from '~/boards/components/board_card_inner.vue';
import { issuableTypes } from '~/boards/constants';

jest.mock('~/flash');

const listIssueProps = {
  project: {
    path: '/test',
  },
  real_path: '',
  webUrl: '',
};

const componentProps = {
  groupId: undefined,
};

const actions = {
  addListNewEpic: jest.fn().mockResolvedValue(),
};

const componentConfig = {
  listIssueProps,
  componentProps,
  getters: {
    isGroupBoard: () => true,
    isProjectBoard: () => false,
    isEpicBoard: () => true,
  },
  state: {
    issuableType: issuableTypes.epic,
  },
  actions,
  stubs: {
    BoardCard,
    BoardCardInner,
    BoardNewEpic,
  },
  provide: {
    scopedLabelsAvailable: true,
  },
};

describe('BoardList Component', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent(componentConfig);
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders link properly in issue', () => {
    expect(wrapper.find('.board-card .board-card-title a').attributes('href')).not.toContain(
      ':project_path',
    );
  });
});
