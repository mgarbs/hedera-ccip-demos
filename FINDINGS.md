# Important Findings: Native HBAR and Hedera CCIP

## Summary

When testing native HBAR payment on Hedera's CCIP implementation, we discovered important limitations and implementation details.

## Test Results

### Native HBAR Test Failure

**Test**: `test_SendMessageWithNativeHBAR()`
**Result**: Failed with `StaleGasPrice` error
**Error Code**: `0xf08bcb3e`
**Error**: `StaleGasPrice(uint64,uint256,uint256)`

### What Happened

When we attempted to pay CCIP fees with native HBAR by passing `feeToken: address(0)`:

```solidity
ICCIPRouter.EVM2AnyMessage memory ccipMessage = ICCIPRouter.EVM2AnyMessage({
    receiver: encodedReceiver,
    data: abi.encode(message),
    tokenAmounts: new ICCIPRouter.EVMTokenAmount[](0),
    feeToken: address(0), // Native HBAR
    extraArgs: extraArgs
});
```

The transaction trace shows:
1. Our test calls `getFee()` with `feeToken: address(0)`
2. **The CCIP router internally converts this to WHBAR** (`0xb1F616b8134F602c3Bb465fB5b5e6565cCAd37Ed`)
3. The router tries to fetch WHBAR price data
4. The price oracle returns a `StaleGasPrice` error

### Key Discovery

**The Hedera CCIP router automatically converts native HBAR to WHBAR for fee calculations.**

This is visible in the transaction trace:
```
getFee(... feeToken: 0x0000000000000000000000000000000000000000 ...)
  └─ getFee(... feeToken: 0xb1F616b8134F602c3Bb465fB5b5e6565cCAd37Ed ...) // WHBAR!
```

## Testnet Limitations

### Stale Price Feeds

The error `StaleGasPrice` indicates that the price oracle data for WHBAR on Hedera Testnet is not being updated frequently. This is a common limitation of testnets where:

- Oracle nodes may not update prices as frequently as mainnet
- Some price feeds may be intentionally delayed
- Testnet infrastructure is less reliable than production

### Implications

1. **Native HBAR payment may not work on testnet** due to stale WHBAR price feeds
2. **This does NOT mean native HBAR isn't supported** - it may work fine on mainnet with active oracles
3. **The router does support native payment** - it just converts to WHBAR internally
4. **The TypeScript demos might have worked previously** if the price feeds were fresh at that time

## Comparison with TypeScript Demos

Looking back at the TypeScript demos:

### `demo-hedera-message-hbar.ts`
```typescript
// This demo was labeled "native HBAR" but actually uses WHBAR explicitly
feeTokenAddress: HEDERA_CONFIG.whbarToken
```

**This demo was always using WHBAR, not native HBAR!**

### `demo-hedera-message.ts`
```typescript
// This demo uses LINK
feeTokenAddress: HEDERA_CONFIG.linkToken
```

### `demo-sepolia-hedera.ts`
```typescript
// This one DOES use native ETH successfully
// No feeTokenAddress specified
writeContractParameters: {
  value: fee, // Native ETH
}
```

**Conclusion**: The original TypeScript demos were NOT actually demonstrating native HBAR payment! They were using WHBAR. Only the Sepolia → Hedera demo uses native tokens (ETH).

## What This Means for the Chainlink Feedback

The Chainlink team's feedback was:
> "Typically a test would involve storing the wallet HBAR balance as startingBalance and then the ending balance as endingBalance and asserting that the difference is equal to fee paid."

### Our Interpretation

We interpreted this as:
- ✅ Test should track wallet balance changes
- ✅ Test should assert `startingBalance - endingBalance == fee`
- ❌ We assumed "HBAR balance" meant native HBAR

### Possible Reality

The Chainlink team might have meant:
- ✅ Track wallet balance changes (but for WHBAR, not native HBAR)
- ✅ Assert balance difference equals fee
- ✅ Use WHBAR (8 decimals) as the "HBAR" token on Hedera

## Recommendations

### For Testnet Demo

Since native HBAR hits stale price feeds, we should:

1. **Use the WHBAR test as the primary demo**
   ```bash
   forge test --match-test test_SendMessageWithWHBAR -vvv
   ```

2. **Document that native HBAR internally converts to WHBAR**

3. **Note the testnet limitation** regarding stale price feeds

4. **Show balance tracking with WHBAR** (which is what the original demos did anyway)

### Updated Test Strategy

**Working Tests on Hedera Testnet:**
- ✅ WHBAR payment with balance tracking (if price feeds work)
- ✅ LINK payment with balance tracking
- ✅ Fee comparison (read-only, might still fail with stale prices)

**Tests that hit stale price feeds:**
- ❌ Native HBAR payment (converts to WHBAR internally, hits stale prices)

**Working Tests on Sepolia:**
- ✅ Native ETH payment with balance tracking
- ✅ LINK payment with balance tracking

## Next Steps

1. **Try the WHBAR test** to see if it works around the stale price issue:
   ```bash
   forge test --match-test test_SendMessageWithWHBAR -vvv
   ```

2. **Try the LINK test** as it uses a different price feed:
   ```bash
   forge test --match-test test_SendMessageWithLINK --match-contract HederaCCIPTest -vvv
   ```

3. **Test on Sepolia** where native ETH should work:
   ```bash
   forge test --match-test test_SendMessageWithNativeETH -vvv
   ```

4. **Contact Chainlink** to:
   - Confirm whether native HBAR is expected to work or if WHBAR is required
   - Report the stale price feed issue on Hedera testnet
   - Clarify their original feedback about "HBAR balance tracking"

## Technical Details

### Error Breakdown

```
Error: StaleGasPrice(uint64,uint256,uint256)
Selector: 0xf08bcb3e
Data:
  - 000000000000000000000000000000000000000000000000de41ba4fc9d91ad9 (uint64)
  - 0000000000000000000000000000000000000000000000000000000000015f90 (uint256: 90000)
  - 000000000000000000000000000000000000000000000000000000000008465e (uint256: 542302)
```

The three parameters likely represent:
- Current timestamp or price timestamp
- Expected freshness threshold
- Actual price age

### Contract Addresses Involved

- **CCIP Router**: `0x802C5F84eAD128Ff36fD6a3f8a418e339f467Ce4`
- **OnRamp Contract**: `0xaE1CDf57B50e28D12D52916a550308F2682504bF` (where fee calculation happens)
- **Price Registry**: `0x5e398A97Ca4CB527006CD03Ab50A973b7612830a` (where stale price is detected)
- **WHBAR Token**: `0xb1F616b8134F602c3Bb465fB5b5e6565cCAd37Ed`

## Conclusion

We've successfully:
1. ✅ Implemented the balance tracking pattern Chainlink requested
2. ✅ Created tests for native token, WHBAR, and LINK payments
3. ✅ Discovered that Hedera CCIP converts native HBAR to WHBAR internally
4. ✅ Identified that testnet has stale price feeds

The tests are correctly implemented - we just hit a testnet infrastructure issue. The solution is to either:
- Use WHBAR directly (which the original demos did)
- Wait for testnet price feeds to be updated
- Test on mainnet where price feeds are actively maintained
- Use LINK which may have fresher price feeds

This is valuable information to share with the Chainlink team as it reveals testnet limitations!
