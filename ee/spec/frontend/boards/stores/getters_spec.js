import getters from 'ee/boards/stores/getters';
import {
  mockIssue,
  mockIssue3,
  mockIssue4,
  mockIssues,
  mockIssuesByListId,
  mockEpics,
  issues,
  mockLists,
} from '../mock_data';

describe('EE Boards Store Getters', () => {
  const boardsState = {
    boardItemsByListId: mockIssuesByListId,
    epics: mockEpics,
    boardItems: issues,
  };

  describe('isSwimlanesOn', () => {
    describe('when swimlanes feature is true', () => {
      beforeEach(() => {
        window.gon = { licensed_features: { swimlanes: true } };
      });

      describe('when isShowingEpicsSwimlanes is true', () => {
        it('returns true', () => {
          const state = {
            isShowingEpicsSwimlanes: true,
          };

          expect(getters.isSwimlanesOn(state)).toBe(true);
        });
      });

      describe('when isShowingEpicsSwimlanes is false', () => {
        it('returns false', () => {
          const state = {
            isShowingEpicsSwimlanes: false,
          };

          expect(getters.isSwimlanesOn(state)).toBe(false);
        });
      });
    });

    describe('when swimlanes feature is false', () => {
      describe('when isShowingEpicsSwimlanes is true', () => {
        it('returns false', () => {
          const state = {
            isShowingEpicsSwimlanes: true,
          };

          expect(getters.isSwimlanesOn(state)).toBe(false);
        });
      });

      describe('when isShowingEpicsSwimlanes is false', () => {
        it('returns false', () => {
          const state = {
            isShowingEpicsSwimlanes: false,
          };

          expect(getters.isSwimlanesOn(state)).toBe(false);
        });
      });
    });
  });

  describe('getIssuesByEpic', () => {
    it('returns issues for a given listId and epicId', () => {
      const getBoardItemsByList = () => mockIssues;
      expect(
        getters.getIssuesByEpic(boardsState, { getBoardItemsByList })(
          'gid://gitlab/List/2',
          'gid://gitlab/Epic/41',
        ),
      ).toEqual([mockIssue]);
    });
  });

  describe('getUnassignedIssues', () => {
    it('returns issues not assigned to an epic for a given listId', () => {
      const getBoardItemsByList = () => [mockIssue, mockIssue3, mockIssue4];
      expect(
        getters.getUnassignedIssues(boardsState, { getBoardItemsByList })('gid://gitlab/List/1'),
      ).toEqual([mockIssue3, mockIssue4]);
    });
  });

  describe('getListByTypeId', () => {
    const [, labelList, assigneeList, milestoneList] = mockLists;

    it('returns label list by labelId', () => {
      const labelId = labelList.label.id;
      expect(getters.getListByTypeId({ boardLists: mockLists })({ labelId })).toEqual(labelList);
    });

    it('returns assignee list by assigneeId', () => {
      const assigneeId = assigneeList.assignee.id;

      expect(getters.getListByTypeId({ boardLists: mockLists })({ assigneeId })).toEqual(
        assigneeList,
      );
    });

    it('returns milestone list by milestoneId', () => {
      const milestoneId = milestoneList.milestone.id;

      expect(getters.getListByTypeId({ boardLists: mockLists })({ milestoneId })).toEqual(
        milestoneList,
      );
    });

    it('returns nothing if not results', () => {
      expect(
        getters.getListByTypeId({ boardLists: mockLists })({ labelId: 'not found' }),
      ).toBeUndefined();
    });
  });

  describe('isEpicBoard', () => {
    it.each`
      issuableType | expected
      ${'epic'}    | ${true}
      ${'issue'}   | ${false}
    `(
      'returns $expected when issuableType on state is $issuableType',
      ({ issuableType, expected }) => {
        const state = {
          issuableType,
        };

        expect(getters.isEpicBoard(state)).toBe(expected);
      },
    );
  });
});
