const fs = require('fs');
const path = require('path');

// Read the Postman collection
const collectionPath = path.join(__dirname, 'CinemaAbyss.postman_collection.json');
const collection = JSON.parse(fs.readFileSync(collectionPath, 'utf8'));

console.log('🔧 Updating Postman collection for Kubernetes Ingress...');

// Function to remove static Host headers (will be added dynamically via pre-request script)
function removeStaticHostHeaders(item) {
  if (item.request && item.request.header) {
    // Remove any existing Host headers
    item.request.header = item.request.header.filter(h => h.key !== 'Host');
    console.log(`🧹 Removed static Host headers from: ${item.name}`);
  }

  // Recursively process sub-items
  if (item.item && Array.isArray(item.item)) {
    item.item.forEach(removeStaticHostHeaders);
  }
}

// Function to update URLs from domain to localhost
function updateUrlsToLocalhost(item) {
  if (item.request && item.request.url) {
    if (typeof item.request.url === 'string') {
      // Simple string URL
      item.request.url = item.request.url.replace('{{baseUrl}}', 'http://127.0.0.1');
      item.request.url = item.request.url.replace('{{moviesServiceUrl}}', 'http://127.0.0.1');
      item.request.url = item.request.url.replace('{{eventsServiceUrl}}', 'http://127.0.0.1');
      item.request.url = item.request.url.replace('{{proxyServiceUrl}}', 'http://127.0.0.1');
    } else if (item.request.url.raw) {
      // Postman URL object
      item.request.url.raw = item.request.url.raw.replace('{{baseUrl}}', 'http://127.0.0.1');
      item.request.url.raw = item.request.url.raw.replace('{{moviesServiceUrl}}', 'http://127.0.0.1');
      item.request.url.raw = item.request.url.raw.replace('{{eventsServiceUrl}}', 'http://127.0.0.1');
      item.request.url.raw = item.request.url.raw.replace('{{proxyServiceUrl}}', 'http://127.0.0.1');

      // Update host array if it exists
      if (item.request.url.host && Array.isArray(item.request.url.host)) {
        item.request.url.host = ['127.0.0.1'];
      }
    }

    console.log(`🔄 Updated URL for: ${item.name}`);
  }

  // Recursively process sub-items
  if (item.item && Array.isArray(item.item)) {
    item.item.forEach(updateUrlsToLocalhost);
  }
}

// Add global pre-request script to collection
const globalPreRequestScript = {
  listen: 'prerequest',
  script: {
    exec: [
      '// Global pre-request script for Kubernetes Ingress',
      'console.log("🌐 Setting up request for Kubernetes Ingress");',
      '',
      '// Remove existing Host header if present',
      'pm.request.headers.remove("Host");',
      '',
      '// Add single Host header for Kubernetes Ingress',
      'pm.request.headers.add({',
      '    key: "Host",',
      '    value: "cinemaabyss.example.com"',
      '});',
      '',
      '// Log request details',
      'console.log(`📡 ${pm.request.method} ${pm.request.url.toString()}`);',
      'console.log("📋 Host header:", pm.request.headers.get("Host"));'
    ],
    type: 'text/javascript'
  }
};

// Add global test script for better error handling
const globalTestScript = {
  listen: 'test',
  script: {
    exec: [
      '// Global test script for better debugging',
      'if (pm.response.code >= 400) {',
      '    console.error(`❌ Request failed with status ${pm.response.code}`);',
      '    console.error("Response body:", pm.response.text());',
      '}',
      '',
      '// Log successful responses',
      'if (pm.response.code < 400) {',
      '    console.log(`✅ Request successful: ${pm.response.code}`);',
      '}'
    ],
    type: 'text/javascript'
  }
};

// Process all items in the collection
console.log('📝 Processing collection items...');
collection.item.forEach(removeStaticHostHeaders);
collection.item.forEach(updateUrlsToLocalhost);

// Add global events to collection
if (!collection.event) {
  collection.event = [];
}

// Remove existing global events of the same type
collection.event = collection.event.filter(e => e.listen !== 'prerequest' && e.listen !== 'test');

// Add new global events
collection.event.push(globalPreRequestScript);
collection.event.push(globalTestScript);

console.log('🎯 Added global pre-request and test scripts');

// Write updated collection back to file
const updatedCollectionPath = path.join(__dirname, 'CinemaAbyss.postman_collection.kubernetes.json');
fs.writeFileSync(updatedCollectionPath, JSON.stringify(collection, null, 2));

console.log(`💾 Updated collection saved to: ${updatedCollectionPath}`);
console.log('🚀 Collection is now ready for Kubernetes Ingress testing!');

// Also update the environment file for consistency
const envPath = path.join(__dirname, 'kubernetes.environment.json');
const env = JSON.parse(fs.readFileSync(envPath, 'utf8'));

env.values = env.values.map(value => {
  if (value.key.includes('Url') || value.key === 'baseUrl') {
    return { ...value, value: 'http://127.0.0.1' };
  }
  return value;
});

fs.writeFileSync(envPath, JSON.stringify(env, null, 2));
console.log(`💾 Updated environment file: ${envPath}`);