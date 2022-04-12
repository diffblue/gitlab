import { checkOverage } from 'ee/invite_members/check_overage';
import {
  freePlanSubsciption,
  oneFreeSeatSubscription,
  noFreePlacesSubscription,
  subscriptionWithOverage,
  allowGuestsSubscription,
  generateInvitedUsersData,
} from './mock_data';

const secondUserAddedById = generateInvitedUsersData({
  usersToAddById: [2],
});

describe('overage check', () => {
  it('returns no overage on free plans', () => {
    const result = checkOverage(freePlanSubsciption, secondUserAddedById);

    expect(result.hasOverage).toBe(false);
  });

  it('returns no overage when there is one free seat', () => {
    const result = checkOverage(
      oneFreeSeatSubscription,
      generateInvitedUsersData({ usersToInviteByEmail: ['new_user@email.com'] }),
    );

    expect(result.hasOverage).toBe(false);
  });

  it('returns overage when new user added by id', () => {
    const result = checkOverage(noFreePlacesSubscription, secondUserAddedById);

    expect(result.hasOverage).toBe(true);
    expect(result.usersOverage).toBe(2);
  });

  it('returns overage when new user added by email', () => {
    const result = checkOverage(
      noFreePlacesSubscription,
      generateInvitedUsersData({ usersToInviteByEmail: ['test2@example'] }),
    );

    expect(result.hasOverage).toBe(true);
    expect(result.usersOverage).toBe(2);
  });

  it('returns overage for only overlapping users added by id', () => {
    const result = checkOverage(
      noFreePlacesSubscription,
      generateInvitedUsersData({ usersToAddById: [1, 2, 3] }),
    );

    expect(result.hasOverage).toBe(true);
    expect(result.usersOverage).toBe(3);
  });

  it('returns overage for only overlapping users added by emails', () => {
    const result = checkOverage(
      noFreePlacesSubscription,
      generateInvitedUsersData({
        usersToInviteByEmail: ['test@example', 'test2@example', 'test3@example'],
      }),
    );

    expect(result.hasOverage).toBe(true);
    expect(result.usersOverage).toBe(3);
  });

  it('returns overage for only overlapping users added by ids and emails', () => {
    const result = checkOverage(
      noFreePlacesSubscription,
      generateInvitedUsersData({
        usersToAddById: [1, 2],
        usersToInviteByEmail: ['test@example', 'test2@example'],
      }),
    );

    expect(result.hasOverage).toBe(true);
    expect(result.usersOverage).toBe(3);
  });

  it('returns no overage if adding a user does not increase seats owed', () => {
    const result = checkOverage(subscriptionWithOverage, secondUserAddedById);

    expect(result.hasOverage).toBe(false);
  });

  describe('for subscriptions that don`\t bill guests', () => {
    it('returns overage on adding developers', () => {
      const result = checkOverage(allowGuestsSubscription, secondUserAddedById);

      expect(result.hasOverage).toBe(true);
      expect(result.usersOverage).toBe(2);
    });

    it('returns no overage on adding guests', () => {
      const result = checkOverage(
        allowGuestsSubscription,
        generateInvitedUsersData({
          isGuestRole: true,
          usersToAddById: [2],
        }),
      );

      expect(result.hasOverage).toBe(false);
    });
  });
});
