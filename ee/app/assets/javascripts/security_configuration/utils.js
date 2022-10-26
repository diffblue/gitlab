export const initFormField = ({ value, required = true, skipValidation = false }) => ({
  value,
  required,
  state: skipValidation ? true : null,
  feedback: null,
});

/**
 * Calculate time difference in minutes between
 * date and now
 * @param startDate date used for calculation
 * @returns {number} number of minutes
 */
export const getTimeDifferenceMinutes = (startDate) => {
  if (!startDate) {
    return 0;
  }

  const timeDifferenceMinutes = (Date.now() - new Date(startDate).getTime()) / 1000 / 60;

  return Math.ceil(timeDifferenceMinutes);
};
