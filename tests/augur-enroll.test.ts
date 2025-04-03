import { expect, it } from 'vitest';
import { Cl } from '@stacks/transactions';

const accounts = simnet.getAccounts();
const deployer = accounts.get('deployer')!;
const wallet1 = accounts.get("wallet_1")!;
const wallet2 = accounts.get('wallet_2')!;

/*
  The test below is an example. To learn more, read the testing documentation here:
  https://docs.hiro.so/stacks/clarinet-js-sdk
*/

it('ensures simnet is well initialised', () => {
  expect(simnet.blockHeight).toBeDefined();
});

it("enroll", () => {
  let res, arg1, arg2;

  arg1 = [Cl.uint(1000000000000), Cl.principal(deployer), Cl.none()];
  res = simnet.callPublicFn('augur-token', 'mint', arg1, deployer);
  expect(res.result).toBeOk(Cl.bool(true));

  arg1 = [Cl.principal(wallet1)]
  res = simnet.callReadOnlyFn('augur-enroll', 'get-user', arg1, wallet1);
  expect(res.result).toBeNone();

  res = simnet.callPublicFn('augur-enroll', 'enroll', arg1, wallet1);
  expect(res.result).toBeErr(Cl.uint(802));

  res = simnet.callPublicFn('augur-enroll', 'enroll', arg1, deployer);
  expect(res.result).toBeOk(Cl.bool(true));

  res = simnet.callReadOnlyFn('augur-enroll', 'get-user', arg1, wallet1);
  expect(res.result).toBeSome(Cl.tuple({ enrolled: Cl.bool(true) }));

  res = simnet.callPublicFn('augur-enroll', 'enroll', arg1, deployer);
  expect(res.result).toBeErr(Cl.uint(801));

  arg1 = [Cl.principal(wallet2)]  
  res = simnet.callPublicFn('augur-enroll', 'enroll', arg1, deployer);
  expect(res.result).toBeOk(Cl.bool(true));

  res = simnet.callReadOnlyFn('augur-enroll', 'get-user', arg1, wallet1);
  expect(res.result).toBeSome(Cl.tuple({ enrolled: Cl.bool(true) }));

  res = simnet.callReadOnlyFn(
    'augur-token', 'get-balance', [Cl.principal(wallet1)], wallet1
  );
  expect(res.result).toBeOk(Cl.uint(1000000000));

  res = simnet.callReadOnlyFn(
    'augur-token', 'get-balance', [Cl.principal(wallet2)], wallet1
  );
  expect(res.result).toBeOk(Cl.uint(1000000000));
});
