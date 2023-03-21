import { __ } from '~/locale';
import { generateBadges as CEGenerateBadges, isDirectMember } from '~/members/utils';

export {
  isGroup,
  isDirectMember,
  isCurrentUser,
  canRemove,
  canRemoveBlockedByLastOwner,
  canResend,
  canUpdate,
} from '~/members/utils';

export const generateBadges = ({ member, isCurrentUser, canManageMembers }) => [
  ...CEGenerateBadges({ member, isCurrentUser, canManageMembers }),
  {
    show: member.usingLicense,
    text: __('Is using seat'),
    variant: 'neutral',
  },
  {
    show: member.groupSso,
    text: __('SAML'),
    variant: 'info',
  },
  {
    show: member.groupManagedAccount,
    text: __('Managed Account'),
    variant: 'info',
  },
  {
    show: member.canOverride,
    text: __('LDAP'),
    variant: 'info',
  },
  {
    show: member.provisionedByThisGroup,
    text: __('Enterprise'),
    variant: 'info',
  },
];

export const canDisableTwoFactor = (member) => {
  return Boolean(member.canDisableTwoFactor);
};

export const canOverride = (member) => member.canOverride && isDirectMember(member);

export const canUnban = (member) => {
  return Boolean(member.banned) && member.canUnban;
};
