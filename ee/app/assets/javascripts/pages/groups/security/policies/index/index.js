import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';
import initSecurityPoliciesList from 'ee/security_orchestration/security_policies_list';

initSecurityPoliciesList(
  document.getElementById('js-group-security-policies-list'),
  NAMESPACE_TYPES.GROUP,
);
