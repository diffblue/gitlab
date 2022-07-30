import { isEqual } from 'lodash';

export function toEqualGraphFixture(received, match) {
  let clearMatch;

  try {
    clearMatch = JSON.parse(JSON.stringify(match, (k, v) => (k === '__typename' ? undefined : v)));
  } catch (e) {
    return { message: 'The comparator value is not an object', pass: false };
  }
  const pass = isEqual(received, clearMatch);
  const message = pass
    ? () => `
        Expected to not be: ${this.utils.printExpected(clearMatch)}
        Received:           ${this.utils.printReceived(received)}
        `
    : () =>
        `
      Expected to be: ${this.utils.printExpected(clearMatch)}
      Received:       ${this.utils.printReceived(received)}
      `;

  return { actual: received, message, pass };
}
