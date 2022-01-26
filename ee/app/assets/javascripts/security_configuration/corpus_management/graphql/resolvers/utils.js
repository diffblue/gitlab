import { I18N, ERROR_RESPONSE } from '../../constants';

export const parseNameError = (error) => {
  if (error === ERROR_RESPONSE.packageNameInvalid || error === ERROR_RESPONSE.notFound) {
    return I18N.invalidName;
  }
  return '';
};

export const parseFileError = (error) => {
  if (error === I18N.fileTooLarge) {
    return I18N.fileTooLarge;
  }
  return '';
};
