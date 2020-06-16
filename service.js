const os = require('os');
const http = require('http');

const bind_address = '0.0.0.0';
const port = 3000;
const hostname = os.hostname();
const service_name = process.argv.length > 2 ?
    process.argv[2] : hostname;


const server = http.createServer((req, res) => {
  res.statusCode = 200;
  res.setHeader('Content-Type', 'text/plain');
  res.setHeader('X-Hostname', hostname);
  res.setHeader('X-Service-Name', service_name);
  res.end(`Hello World, from ${service_name}!\n`);
});

server.listen(port, hostname, () => {
  console.log(`Server running at http://${bind_address}:${port}/`);
});
