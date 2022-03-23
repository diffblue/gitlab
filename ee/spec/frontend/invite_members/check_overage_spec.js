import { checkOverage } from 'ee/invite_members/check_overage';
import {
  freePlanSubsciption,
  oneFreeSeatSubscription,
  noFreePlacesSubscription,
  subscriptionWithOverage,
} from './mock_data';

describe('overage check', () => {
  it('returns no overage on free plans', () => {
    const result = checkOverage(freePlanSubsciption, [], []);

    expect(result.hasOverage).toBe(false);
  });

  it('returns no overage when there is one free seat', () => {
    const result = checkOverage(oneFreeSeatSubscription, [], ['new_user@email.com']);

    expect(result.hasOverage).toBe(false);
  });

  it('returns overage when new user added by id', () => {
    const result = checkOverage(noFreePlacesSubscription, [2], []);

    expect(result.hasOverage).toBe(true);
    expect(result.usersOverage).toBe(2);
  });

  it('returns overage when new user added by email', () => {
    const result = checkOverage(noFreePlacesSubscription, [], ['test2@example']);

    expect(result.hasOverage).toBe(true);
    expect(result.usersOverage).toBe(2);
  });

  it('returns overage for only overlapping users added by id', () => {
    const result = checkOverage(noFreePlacesSubscription, [1, 2, 3], []);

    expect(result.hasOverage).toBe(true);
    expect(result.usersOverage).toBe(3);
  });

  it('returns overage for only overlapping users added by emails', () => {
    const result = checkOverage(
      noFreePlacesSubscription,
      [],
      ['test@example', 'test2@example', 'test3@example'],
    );

    expect(result.hasOverage).toBe(true);
    expect(result.usersOverage).toBe(3);
  });

  it('returns overage for only overlapping users added by ids and emails', () => {
    const result = checkOverage(
      noFreePlacesSubscription,
      [1, 2],
      ['test@example', 'test2@example'],
    );

    expect(result.hasOverage).toBe(true);
    expect(result.usersOverage).toBe(3);
  });

  it('returns no overage if adding a user does not increase seats owed', () => {
    const result = checkOverage(subscriptionWithOverage, [2], []);

    expect(result.hasOverage).toBe(false);
  });
});
