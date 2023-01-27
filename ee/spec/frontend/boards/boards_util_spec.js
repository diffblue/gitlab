import {
  formatEpic,
  formatListEpics,
  formatEpicListsPageInfo,
  transformBoardConfig,
  formatIssueInput,
  formatEpicInput,
} from 'ee/boards/boards_util';
import { IterationIDs } from 'ee/boards/constants';
import setWindowLocation from 'helpers/set_window_location_helper';
import { mockLabel } from './mock_data';

const listId = 'gid://gitlab/Boards::EpicList/3';
const epicId = 'gid://gitlab/Epic/1';

describe('formatEpic', () => {
  it('formats raw epic object for state', () => {
    const labels = [
      {
        id: 1,
        title: 'bug',
      },
    ];

    const rawEpic = {
      id: epicId,
      title: 'Foo',
      labels: {
        nodes: labels,
      },
    };

    expect(formatEpic(rawEpic)).toEqual({
      ...rawEpic,
      labels,
      // Until we add support for assignees within Epics,
      // we need to pass it as an empty array.
      assignees: [],
    });
  });
});

describe('formatListEpics', () => {
  it('formats raw response from list epics for state', () => {
    const rawEpicsInLists = {
      nodes: [
        {
          id: 'gid://gitlab/Boards::EpicList/3',
          epicsCount: 1,
          epics: {
            nodes: [
              {
                title: 'epic title',
                id: epicId,
                labels: {
                  nodes: [mockLabel],
                },
              },
            ],
          },
        },
      ],
    };

    const result = formatListEpics(rawEpicsInLists);

    expect(result).toEqual({
      boardItems: {
        [epicId]: {
          assignees: [],
          id: epicId,
          labels: [mockLabel],
          title: 'epic title',
        },
      },
      listData: { [listId]: [epicId] },
      listItemsCount: 1,
    });
  });
});

describe('formatEpicListsPageInfo', () => {
  it('formats raw pageInfo response from epics for state', () => {
    const rawEpicsInListsPageInfo = {
      nodes: [
        {
          id: listId,
          epics: {
            pageInfo: {
              endCursor: 'MjA',
              hasNextPage: true,
            },
          },
        },
      ],
    };

    const result = formatEpicListsPageInfo(rawEpicsInListsPageInfo);

    expect(result).toEqual({
      [listId]: {
        endCursor: 'MjA',
        hasNextPage: true,
      },
    });
  });
});

describe('formatIssueInput', () => {
  const issueInput = {
    labelIds: ['gid://gitlab/GroupLabel/5'],
    projectPath: 'gitlab-org/gitlab-test',
    id: 'gid://gitlab/Issue/11',
  };

  const expected = {
    projectPath: 'gitlab-org/gitlab-test',
    id: 'gid://gitlab/Issue/11',
    labelIds: ['gid://gitlab/GroupLabel/5'],
    assigneeIds: [],
    milestoneId: undefined,
  };

  it('adds iterationWildcardId to when current iteration selected', () => {
    const boardConfig = {
      iterationId: IterationIDs.CURRENT,
    };

    const result = formatIssueInput(issueInput, boardConfig);

    expect(result).toEqual({
      ...expected,
      iterationWildcardId: 'CURRENT',
      iterationCadenceId: null,
    });
  });

  it('includes iterationCadenceId and iterationId', () => {
    const boardConfig = {
      iterationId: 66,
      iterationCadenceId: 11,
    };

    const result = formatIssueInput(issueInput, boardConfig);

    expect(result).toEqual({
      ...expected,
      iterationCadenceId: 'gid://gitlab/Iterations::Cadence/11',
      iterationId: 'gid://gitlab/Iteration/66',
    });
  });
});

describe('transformBoardConfig', () => {
  const boardConfig = {
    milestoneTitle: 'milestone',
    assigneeUsername: 'username',
    labels: [
      { id: 5, title: 'Deliverable', color: '#34ebec', type: 'GroupLabel', textColor: '#333333' },
      { id: 6, title: 'On hold', color: '#34ebec', type: 'GroupLabel', textColor: '#333333' },
    ],
    weight: 0,
    iterationId: 'gid://gitlab/Iteration/1',
    iterationCadenceId: 'gid://gitlab/Iteration::Cadence/1',
  };

  it('formats url parameters from boardConfig object', () => {
    const result = transformBoardConfig(boardConfig);

    expect(result).toBe(
      'milestone_title=milestone&iteration_id=1&weight=0&assignee_username=username&label_name[]=Deliverable&label_name[]=On%20hold',
    );
  });

  it('formats url parameters from boardConfig object preventing duplicates with passed filter query', () => {
    setWindowLocation('?label_name[]=Deliverable&label_name[]=On%20hold');
    const result = transformBoardConfig(boardConfig);

    expect(result).toBe(
      'milestone_title=milestone&iteration_id=1&weight=0&assignee_username=username',
    );
  });

  it('adds iteration_cadence_id when iteration param is any', () => {
    const boardConfigWithCadence = {
      iterationId: IterationIDs.ANY,
      iterationCadenceId: 'gid://gitlab/Iteration::Cadence/1',
    };

    const result = transformBoardConfig(boardConfigWithCadence);

    expect(result).toBe('iteration_id=Any&iteration_cadence_id=1');
  });

  it('adds iteration_cadence_id when iteration param is current', () => {
    const boardConfigWithCadence = {
      iterationId: IterationIDs.CURRENT,
      iterationCadenceId: 'gid://gitlab/Iteration::Cadence/1',
    };

    const result = transformBoardConfig(boardConfigWithCadence);

    expect(result).toBe('iteration_id=Current&iteration_cadence_id=1');
  });
});

describe('formatEpicInput', () => {
  const epicInput = {
    groupPath: 'gitlab-org',
    id: 'gid://gitlab/Epic/11',
    title: 'Epic',
    labelIds: [6],
  };
  const expected = {
    groupPath: 'gitlab-org',
    id: 'gid://gitlab/Epic/11',
    title: 'Epic',
  };

  const boardConfig = {
    labelIds: ['gid://gitlab/GroupLabel/5'],
  };

  it('adds labelsIds to input', () => {
    const result = formatEpicInput(epicInput, boardConfig);

    expect(result).toEqual({
      addLabelIds: [6, 5],
      ...expected,
    });
  });
});
