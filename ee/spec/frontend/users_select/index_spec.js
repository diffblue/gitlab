import htmlEeMrMultipleAssignees from 'test_fixtures/ee/merge_requests/merge_request_with_multiple_assignees_feature.html';
import {
  createInputsModelExpectation,
  createAssignedExpectation,
  createTestContext,
  findDropdownItemsModel,
  findDropdownItem,
  findAssigneesInputsModel,
  getUsersFixtureAt,
  setAssignees,
  toggleDropdown,
  waitForDropdownItems,
} from 'jest/users_select/test_helper';

describe('EE ~/users_select/index with multiple assignees', () => {
  const context = createTestContext({ fixture: htmlEeMrMultipleAssignees });

  beforeEach(() => {
    context.setup();
  });

  afterEach(() => {
    context.teardown();
  });

  describe('when opened', () => {
    beforeEach(async () => {
      context.createSubject();

      toggleDropdown();
      await waitForDropdownItems();
    });

    describe('when users are selected', () => {
      const selectedUsers = [getUsersFixtureAt(2), getUsersFixtureAt(4)];
      const expectation = createAssignedExpectation({
        header: 'Assignees',
        assigned: selectedUsers,
      });

      beforeEach(() => {
        selectedUsers.forEach((user) => {
          findDropdownItem(user).click();
        });
      });

      it('shows assignee', () => {
        expect(findDropdownItemsModel()).toEqual(expectation);
      });

      it('shows assignee even after close and open', () => {
        toggleDropdown();
        toggleDropdown();

        expect(findDropdownItemsModel()).toEqual(expectation);
      });

      it('updates field', () => {
        expect(findAssigneesInputsModel()).toEqual(createInputsModelExpectation(selectedUsers));
      });
    });
  });

  describe('with preselected user and opened', () => {
    const expectation = createAssignedExpectation({
      header: 'Assignees',
      assigned: [getUsersFixtureAt(0)],
    });

    beforeEach(async () => {
      setAssignees(getUsersFixtureAt(0));

      context.createSubject();

      toggleDropdown();
      await waitForDropdownItems();
    });

    it('shows users', () => {
      expect(findDropdownItemsModel()).toEqual(expectation);
    });

    // Regression test for https://gitlab.com/gitlab-org/gitlab/-/issues/325991
    describe('when closed and reopened', () => {
      beforeEach(() => {
        toggleDropdown();
        toggleDropdown();
      });

      it('shows users', () => {
        expect(findDropdownItemsModel()).toEqual(expectation);
      });
    });
  });
});
