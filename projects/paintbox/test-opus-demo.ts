// Simple test file to demonstrate Claude Opus-4 review
export function vulnerableFunction(userInput: string) {
  // SQL injection vulnerability
  const query = `SELECT * FROM users WHERE name = '${userInput}'`;
  return db.execute(query);
}

// Missing error handling
export async function riskyOperation() {
  const data = await fetch('/api/data');
  return data.json(); // No status check
}

// Type safety issue
export function processItems(items: any[]) {
  return items.map(item => item.value * 2); // Could fail
}