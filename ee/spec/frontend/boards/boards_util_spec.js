import {
  formatEpic,
  formatListEpics,
  formatEpicListsPageInfo,
  transformBoardConfig,
} from 'ee/boards/boards_util';
import setWindowLocation from 'helpers/set_window_location_helper';
import { mockLabel } from './mock_data';

const listId = 'gid://gitlab/Boards::EpicList/3';

describe('formatEpic', () => {
  it('formats raw epic object for state', () => {
    const labels = [
      {
        id: 1,
        title: 'bug',
      },
    ];

    const rawEpic = {
      id: 1,
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
            edges: [
              {
                node: {
                  title: 'epic title',
                  id: 'gid://gitlab/Epic/1',
                  labels: {
                    nodes: [mockLabel],
                  },
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
        1: {
          assignees: [],
          id: 1,
          fullId: 'gid://gitlab/Epic/1',
          labels: [mockLabel],
          title: 'epic title',
        },
      },
      listData: { [listId]: [1] },
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

describe('transformBoardConfig', () => {
  const boardConfig = {
    milestoneTitle: 'milestone',
    assigneeUsername: 'username',
    labels: [
      { id: 5, title: 'Deliverable', color: '#34ebec', type: 'GroupLabel', textColor: '#333333' },
      { id: 6, title: 'On hold', color: '#34ebec', type: 'GroupLabel', textColor: '#333333' },
    ],
    weight: 0,
  };

  it('formats url parameters from boardConfig object', () => {
    const result = transformBoardConfig(boardConfig);

    expect(result).toBe(
      'milestone_title=milestone&weight=0&assignee_username=username&label_name[]=Deliverable&label_name[]=On%20hold',
    );
  });

  it('formats url parameters from boardConfig object preventing duplicates with passed filter query', () => {
    setWindowLocation('?label_name[]=Deliverable&label_name[]=On%20hold');
    const result = transformBoardConfig(boardConfig);

    expect(result).toBe('milestone_title=milestone&weight=0&assignee_username=username');
  });
});
