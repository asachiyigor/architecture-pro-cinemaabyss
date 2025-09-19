const newman = require('newman');
const path = require('path');

console.log('🚀 Starting CinemaAbyss Kubernetes Ingress Tests...');
console.log('📡 Testing via Kubernetes Ingress with Host header: cinemaabyss.example.com');

const options = {
  collection: path.join(__dirname, 'CinemaAbyss.postman_collection.kubernetes.json'),
  environment: path.join(__dirname, 'kubernetes.environment.json'),
  reporters: ['cli', 'json'],
  reporter: {
    cli: {
      showTimestamps: true,
      silent: false
    },
    json: {
      export: path.join(__dirname, 'test-results-kubernetes.json')
    }
  },
  iterationCount: 1,
  delayRequest: 1000, // 1 second delay between requests
  timeout: 30000, // 30 second timeout
  insecure: true, // Accept self-signed certificates
  bail: false, // Continue on test failures
  color: 'auto'
};

console.log('🔧 Test Configuration:');
console.log(`   Collection: ${options.collection}`);
console.log(`   Environment: ${options.environment}`);
console.log(`   Delay: ${options.delayRequest}ms between requests`);
console.log(`   Timeout: ${options.timeout}ms per request`);
console.log('');

newman.run(options, function (err, summary) {
  if (err) {
    console.error('❌ Newman run failed:', err);
    process.exit(1);
  }

  console.log('');
  console.log('📊 TEST SUMMARY');
  console.log('================================');
  console.log(`⏱️  Total time: ${summary.run.timings.completed - summary.run.timings.started}ms`);
  console.log(`📨 Requests: ${summary.run.stats.requests.total} total, ${summary.run.stats.requests.failed} failed`);
  console.log(`🧪 Tests: ${summary.run.stats.tests.total} total, ${summary.run.stats.tests.failed} failed`);
  console.log(`✔️  Assertions: ${summary.run.stats.assertions.total} total, ${summary.run.stats.assertions.failed} failed`);

  if (summary.run.failures && summary.run.failures.length > 0) {
    console.log('');
    console.log('❌ FAILURES:');
    console.log('================================');
    summary.run.failures.forEach((failure, index) => {
      console.log(`${index + 1}. ${failure.error.name}: ${failure.error.message}`);
      if (failure.source && failure.source.name) {
        console.log(`   Source: ${failure.source.name}`);
      }
    });
  }

  console.log('');

  if (summary.run.stats.requests.failed === 0 && summary.run.stats.assertions.failed === 0) {
    console.log('🎉 All tests passed! Kubernetes Ingress is working correctly!');
    console.log('✅ CinemaAbyss API accessible via cinemaabyss.example.com');
  } else {
    console.log('⚠️  Some tests failed. Check the output above for details.');
    console.log('💡 Make sure Kubernetes Ingress is properly configured and running.');
  }

  // Save detailed results
  const resultPath = path.join(__dirname, 'test-results-kubernetes.json');
  console.log(`📋 Detailed results saved to: ${resultPath}`);

  process.exit(summary.run.stats.assertions.failed > 0 ? 1 : 0);
});