export const formHasError = (state) => Object.values(state.formErrors).some((val) => Boolean(val));
