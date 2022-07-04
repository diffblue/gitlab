import { member } from 'jest/members/mock_data';

export * from 'jest/members/mock_data';

export const bannedMember = {
  ...member,
  banned: true,
};
