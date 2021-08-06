import { DAST_SITE_VALIDATION_STATUS } from 'ee/security_configuration/dast_site_validation/constants';

export const dastSiteValidationCreate = (errors = []) => ({
  data: {
    dastSiteValidationCreate: { status: DAST_SITE_VALIDATION_STATUS.PENDING, id: '1', errors },
  },
});

export const dastSiteTokenCreate = ({ id = '1', token = '1', errors = [] }) => ({
  data: {
    dastSiteTokenCreate: {
      id,
      token,
      errors,
    },
  },
});

export const dastSiteValidationRevoke = (errors = []) => ({
  data: {
    dastSiteValidationRevoke: { errors },
  },
});
