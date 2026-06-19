/** Format a number in Indian numbering system (lakhs, crores). */
export function IndianNumber(n: number): string {
  if (!isFinite(n)) return '0';
  const abs = Math.abs(n);
  if (abs >= 1_00_00_000) return `${(n / 1_00_00_000).toFixed(1)}Cr`;
  if (abs >= 1_00_000)    return `${(n / 1_00_000).toFixed(1)}L`;
  if (abs >= 1_000)       return `${(n / 1_000).toFixed(1)}K`;
  return n.toLocaleString('en-IN');
}
