import { expect, it } from "vitest";
import { Cl } from '@stacks/transactions';

const accounts = simnet.getAccounts();
const wallet1 = accounts.get("wallet_1")!;

/*
  The test below is an example. To learn more, read the testing documentation here:
  https://docs.hiro.so/stacks/clarinet-js-sdk
*/

it("ensures simnet is well initalised", () => {
  expect(simnet.blockHeight).toBeDefined();
});

it("get-heights and get-usd-per-btc", () => {
  let cRes;

  cRes = simnet.callReadOnlyFn('playground', 'get-heights', [Cl.uint(1)], wallet1);
  console.log(JSON.stringify(cRes.result));

  cRes = simnet.callReadOnlyFn('playground', 'get-usd-per-btc', [Cl.uint(1)], wallet1);
  console.log(JSON.stringify(cRes.result));
});
