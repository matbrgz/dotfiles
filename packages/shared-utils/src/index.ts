import pc from 'picocolors';

export function formatTable(rows: string[][], gap = 2) {
  if (rows.length === 0) return '';
  const colWidths = rows[0].map((_, i) => Math.max(...rows.map(row => row[i]?.length || 0)));
  return rows.map(row => 
    row.map((cell, i) => cell.padEnd(colWidths[i] + gap)).join('')
  ).join('\n');
}
