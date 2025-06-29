
import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.14.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

// Helper for getting error codes from receipts
function getErrCode(receipt: any): number {
  if (receipt.result.startsWith('(err ')) {
    const errValue = receipt.result.substring(5, receipt.result.length - 1);
    return parseInt(errValue.substring(1));
  }
  return -1;
}

Clarinet.test({
  name: "Ensure that contract can be initialized",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const oracle1 = accounts.get('wallet_1')!;
    const oracle2 = accounts.get('wallet_2')!;
    const oracle3 = accounts.get('wallet_3')!;
    
    // Initialize with 3 oracles
    let block = chain.mineBlock([
      Tx.contractCall(
        'prediction-market', 
        'initialize', 
        [
          types.list([
            types.principal(oracle1.address),
            types.principal(oracle2.address),
            types.principal(oracle3.address)
          ])
        ], 
        deployer.address
      )
    ]);
    
    // Check initialization succeeded
    assertEquals(block.receipts[0].result, '(ok true)');
    assertEquals(block.height, 2);
  },
});

// Helper function to check if a result starts with a prefix
function assertTrue(condition: boolean) {
  assertEquals(condition, true);
}
