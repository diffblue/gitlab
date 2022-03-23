import { difference } from 'lodash';

/**
 * This method checks if adding given users (by ids or email) or a group id
 * will trigger an overage.
 *
 * Returns the boolean flag if overage is present and a total count of users
 * to be billed in case of overage
 *
 *  @param {Object} subscriptionData           Data from related subscription
 *    @param {Number} subscriptionSeats
 *    @param {Number} maxSeatsUsed             Maximum of seats being used for this subscription
 *    @param {Number} seatsInUse               Amount of seats currently in use
 *    @param {Array} billedUserIds             Array of ids of already billed users
 *    @param {Array} billedUserEmails          Array of emails of already billed users
 *    @param {Boolean} isFreePlan
 *  @param {Array} usersToInviteByEmail        Array emails of users to be invited by email
 *  @param {Array} usersToAddById              Array ids of users to be invited by id
 *  @param {Number} groupIdToInvite             namespaceId of the added group
 *
 * @returns {Object}
 */

export const checkOverage = (
  { subscriptionSeats, maxSeatsUsed, seatsInUse, billedUserIds, billedUserEmails, isFreeGroup },
  usersToAddById,
  usersToInviteByEmail,
) => {
  // overage only possible on paid plans
  if (isFreeGroup) {
    return { usersOverage: null, hasOverage: false };
  }

  // we could add a user to already overfilled group
  const initialUserCount = subscriptionSeats < maxSeatsUsed ? maxSeatsUsed : subscriptionSeats;
  const addedByIdUsersCount = difference(usersToAddById, billedUserIds).length;
  const addedByEmailUsersCount = difference(usersToInviteByEmail, billedUserEmails).length;
  const totalUserCount = seatsInUse + addedByIdUsersCount + addedByEmailUsersCount;

  return {
    usersOverage: totalUserCount,
    hasOverage: initialUserCount < totalUserCount,
  };
};
