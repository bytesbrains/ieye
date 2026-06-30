// Display formatting for on-chain contribution amounts.
//
// Amounts are stored wei-native as integer strings (ContributionDoc.amountWei in
// types.ts). We do NOT yet have per-asset decimals metadata from the backend, and
// an ERC-20 may use 6, 8, or 18 decimals — so we cannot safely convert wei → token
// units here without guessing. Until the backend provides decimals (#42), render
// the integer with digit grouping so it's at least readable, and keep this the
// single chokepoint to upgrade to proper decimal/symbol formatting later.

export function formatAmount(amountWei?: string, asset?: string): string {
  if (!amountWei) return "—";
  let grouped: string;
  try {
    grouped = BigInt(amountWei).toLocaleString("en-US");
  } catch {
    // Non-integer / unexpected value — show as-is rather than crash the page.
    grouped = amountWei;
  }
  return `${grouped} ${asset ?? "wei"}`;
}

// Fiat amounts are stored in MINOR units (cents) as integer strings
// (ContributionDoc.amountMinor). Render them as a localized currency string.
export function formatFiatMinor(amountMinor?: string, currency?: string): string {
  if (!amountMinor) return "—";
  const cur = (currency ?? "SGD").toUpperCase();
  try {
    const major = Number(BigInt(amountMinor)) / 100;
    return new Intl.NumberFormat("en-SG", { style: "currency", currency: cur }).format(major);
  } catch {
    return `${amountMinor} ${cur}`;
  }
}
