// Test file for Claude Opus-4 review
// Contains intentional issues for demonstration

import React, { useState } from 'react';

// Security issue: SQL injection vulnerability
export function searchUsers(query: string) {
  // Direct string concatenation - vulnerable to SQL injection
  const sql = `SELECT * FROM users WHERE name LIKE '%${query}%'`;
  console.log('Executing query:', sql);
  // return db.query(sql);
}

// Performance issue: Inefficient array operations
export function processLargeDataset(data: any[]) {
  let result = [];
  // Nested loops - O(n²) complexity
  for (let i = 0; i < data.length; i++) {
    for (let j = 0; j < data.length; j++) {
      if (data[i].id === data[j].parentId) {
        result.push({ ...data[i], parent: data[j] });
      }
    }
  }
  return result;
}

// React component with multiple issues
export function UserDashboard() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(false);
  
  // Missing error handling
  async function loadUsers() {
    setLoading(true);
    const response = await fetch('/api/users');
    const data = await response.json();
    setUsers(data);
    setLoading(false);
  }
  
  // useEffect missing dependencies
  React.useEffect(() => {
    loadUsers();
  }, []); // Missing loadUsers dependency
  
  // Potential memory leak - no cleanup
  React.useEffect(() => {
    const timer = setInterval(() => {
      console.log('Polling for updates...');
      loadUsers();
    }, 5000);
    // Missing cleanup
  }, []);
  
  return (
    <div>
      {loading && <p>Loading...</p>}
      {users.map((user: any) => (
        // Missing key prop
        <div>
          <h3>{user.name}</h3>
          <p>{user.email}</p>
        </div>
      ))}
    </div>
  );
}

// Type safety issues
export function calculatePrice(item: any) {
  // No type checking
  return item.price * item.quantity * (1 - item.discount);
}

// Security: Exposed sensitive data
export const API_CONFIG = {
  endpoint: 'https://api.example.com',
  apiKey: 'sk-1234567890abcdef', // Exposed API key
  secret: 'super-secret-key'
};