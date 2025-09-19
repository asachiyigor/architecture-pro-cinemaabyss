const dns = require('dns');
const dgram = require('dgram');

class LocalDNSServer {
  constructor(port = 5353) {
    this.port = port;
    this.server = dgram.createSocket('udp4');
    this.domains = {
      'cinemaabyss.example.com': '127.0.0.1'
    };
  }

  start() {
    this.server.on('error', (err) => {
      console.error(`DNS Server error: ${err}`);
      this.server.close();
    });

    this.server.on('message', (msg, rinfo) => {
      try {
        this.handleDNSQuery(msg, rinfo);
      } catch (error) {
        console.error('Error handling DNS query:', error);
      }
    });

    this.server.on('listening', () => {
      const address = this.server.address();
      console.log(`🌐 Local DNS Server running on ${address.address}:${address.port}`);
      console.log(`📍 Registered domains:`);
      Object.entries(this.domains).forEach(([domain, ip]) => {
        console.log(`   ${domain} -> ${ip}`);
      });
    });

    this.server.bind(this.port);
  }

  handleDNSQuery(msg, rinfo) {
    // Simple DNS response for our domain
    const query = this.parseDNSQuery(msg);

    if (query && this.domains[query.name]) {
      const response = this.createDNSResponse(msg, query, this.domains[query.name]);
      this.server.send(response, rinfo.port, rinfo.address);
      console.log(`✅ DNS Query: ${query.name} -> ${this.domains[query.name]} (from ${rinfo.address}:${rinfo.port})`);
    } else if (query) {
      // Forward to real DNS server
      console.log(`🔄 Forwarding DNS query for ${query.name} to system DNS`);
    }
  }

  parseDNSQuery(msg) {
    // Basic DNS query parsing
    if (msg.length < 12) return null;

    let offset = 12; // Skip header
    let name = '';

    while (offset < msg.length && msg[offset] !== 0) {
      const len = msg[offset];
      if (len === 0) break;

      if (name) name += '.';
      name += msg.toString('utf8', offset + 1, offset + 1 + len);
      offset += len + 1;
    }

    return { name };
  }

  createDNSResponse(originalMsg, query, ip) {
    // Create a basic DNS response
    const response = Buffer.alloc(originalMsg.length + 16);

    // Copy original header and modify flags
    originalMsg.copy(response, 0, 0, 12);
    response[2] = 0x81; // Response flag
    response[3] = 0x80; // Authoritative answer

    // Copy question section
    originalMsg.copy(response, 12);

    // Add answer section at the end
    let offset = originalMsg.length;

    // Name pointer (compression)
    response[offset++] = 0xc0;
    response[offset++] = 0x0c;

    // Type A
    response[offset++] = 0x00;
    response[offset++] = 0x01;

    // Class IN
    response[offset++] = 0x00;
    response[offset++] = 0x01;

    // TTL (300 seconds)
    response[offset++] = 0x00;
    response[offset++] = 0x00;
    response[offset++] = 0x01;
    response[offset++] = 0x2c;

    // Data length
    response[offset++] = 0x00;
    response[offset++] = 0x04;

    // IP address
    const ipParts = ip.split('.');
    response[offset++] = parseInt(ipParts[0]);
    response[offset++] = parseInt(ipParts[1]);
    response[offset++] = parseInt(ipParts[2]);
    response[offset++] = parseInt(ipParts[3]);

    // Update answer count
    response[7] = 0x01;

    return response.slice(0, offset);
  }

  stop() {
    this.server.close();
    console.log('🛑 DNS Server stopped');
  }
}

// Start DNS server
const dnsServer = new LocalDNSServer();
dnsServer.start();

// Graceful shutdown
process.on('SIGTERM', () => dnsServer.stop());
process.on('SIGINT', () => dnsServer.stop());