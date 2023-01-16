import { generateBadges, canDisableTwoFactor, canOverride, canUnban } from 'ee/members/utils';
import { member as memberMock, directMember, inheritedMember } from 'jest/members/mock_data';

describe('Members Utils', () => {
  describe('generateBadges', () => {
    it('has correct properties for each badge', () => {
      const badges = generateBadges({
        member: memberMock,
        isCurrentUser: true,
        canManageMembers: true,
      });

      badges.forEach((badge) => {
        expect(badge).toEqual(
          expect.objectContaining({
            show: expect.any(Boolean),
            text: expect.any(String),
            variant: expect.stringMatching(/muted|neutral|info|success|danger|warning/),
          }),
        );
      });
    });

    it.each`
      member                                             | expected
      ${{ ...memberMock, usingLicense: true }}           | ${{ show: true, text: 'Is using seat', variant: 'neutral' }}
      ${{ ...memberMock, groupSso: true }}               | ${{ show: true, text: 'SAML', variant: 'info' }}
      ${{ ...memberMock, groupManagedAccount: true }}    | ${{ show: true, text: 'Managed Account', variant: 'info' }}
      ${{ ...memberMock, canOverride: true }}            | ${{ show: true, text: 'LDAP', variant: 'info' }}
      ${{ ...memberMock, provisionedByThisGroup: true }} | ${{ show: true, text: 'Enterprise', variant: 'info' }}
    `('returns expected output for "$expected.text" badge', ({ member, expected }) => {
      expect(
        generateBadges({ member, isCurrentUser: true, canManageMembers: true }),
      ).toContainEqual(expect.objectContaining(expected));
    });
  });

  describe('canDisableTwoFactor', () => {
    it.each`
      member                                           | expected
      ${{ ...memberMock, canDisableTwoFactor: true }}  | ${true}
      ${{ ...memberMock, canDisableTwoFactor: false }} | ${false}
    `(
      'returns $expected for members whose two factor authentication can be disabled',
      ({ member, expected }) => {
        expect(canDisableTwoFactor(member)).toBe(expected);
      },
    );
  });

  describe('canOverride', () => {
    it.each`
      member                                        | expected
      ${{ ...directMember, canOverride: true }}     | ${true}
      ${{ ...inheritedMember, canOverride: true }}  | ${false}
      ${{ ...directMember, canOverride: false }}    | ${false}
      ${{ ...inheritedMember, canOverride: false }} | ${false}
    `('returns $expected', ({ member, expected }) => {
      expect(canOverride(member)).toBe(expected);
    });
  });

  describe('canUnban', () => {
    it.each`
      member                                               | expected
      ${{ ...memberMock, banned: true, canUnban: true }}   | ${true}
      ${{ ...memberMock, banned: true, canUnban: false }}  | ${false}
      ${{ ...memberMock, banned: false, canUnban: true }}  | ${false}
      ${{ ...memberMock, banned: false, canUnban: false }} | ${false}
    `(
      'returns $expected for "member banned $member.banned and member canUnban $member.canUnban"',
      ({ member, expected }) => {
        expect(canUnban(member)).toBe(expected);
      },
    );
  });
});
