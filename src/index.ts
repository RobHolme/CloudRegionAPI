import fs from 'fs';
import express, { Request, Response } from "express";
import ipRoutes from "./routes/ip";
import { cloudProviderJSON } from './util/cloudprovider-utils'

// create a new express application instance
const app = express();
const PORT = process.env.PORT || 80;
app.use(express.json());

// define the routes
app.use("/ip", ipRoutes);

// handle requests for the root URL
app.get("/", (req: Request, res: Response) => {
  res.send("Welcome");
});

// handle requests for the /info URL
app.get("/info", (req: Request, res: Response) => {
  res.setHeader('content-type', 'application/json');
  var jsonResult: Object = {
    ClientIP: req.ip,
    Protocol: req.protocol,
    HTTPVersion: req.httpVersion,
    Headers: req.headers
  };
  res.send(JSON.stringify(jsonResult, null, 2));
});

// handle requests for the /azure URL, Return the full list of Azure subnets
app.get("/azure", (req: Request, res: Response) => {
  res.setHeader('content-type', 'application/json');
  var azureSubnets: cloudProviderJSON[] = JSON.parse(fs.readFileSync('./release/cloudproviders/Azure.json', 'utf-8'));
  res.send(JSON.stringify(azureSubnets, null, 2));
});

// handle requests for the /aws URL, Return the full list of AWS subnets
app.get("/aws", (req: Request, res: Response) => {
  res.setHeader('content-type', 'application/json');
  var azureSubnets: cloudProviderJSON[] = JSON.parse(fs.readFileSync('./release/cloudproviders/AWS.json', 'utf-8'));
  res.send(JSON.stringify(azureSubnets, null, 2));
});

// handle requests for the /google URL, Return the full list of GoogleCloud subnets
app.get("/google", (req: Request, res: Response) => {
  res.setHeader('content-type', 'application/json');
  var azureSubnets: cloudProviderJSON[] = JSON.parse(fs.readFileSync('./release/cloudproviders/GoogleCloud.json', 'utf-8'));
  res.send(JSON.stringify(azureSubnets, null, 2));
});

// handle requests for the /oci URL, Return the full list of OCI subnets
app.get("/oci", (req: Request, res: Response) => {
  res.setHeader('content-type', 'application/json');
  var azureSubnets: cloudProviderJSON[] = JSON.parse(fs.readFileSync('./release/cloudproviders/OCI.json', 'utf-8'));
  res.send(JSON.stringify(azureSubnets, null, 2));
});

// handle requests for the /akamai URL, Return the full list of Akamai subnets
app.get("/akamai", (req: Request, res: Response) => {
  res.setHeader('content-type', 'application/json');
  var azureSubnets: cloudProviderJSON[] = JSON.parse(fs.readFileSync('./release/cloudproviders/Akamai.json', 'utf-8'));
  res.send(JSON.stringify(azureSubnets, null, 2));
});

// handle requests for the /cloudflare URL, Return the full list of CloudFlare subnets
app.get("/cloudflare", (req: Request, res: Response) => {
  res.setHeader('content-type', 'application/json');
  var azureSubnets: cloudProviderJSON[] = JSON.parse(fs.readFileSync('./release/cloudproviders/CloudFlare.json', 'utf-8'));
  res.send(JSON.stringify(azureSubnets, null, 2));
});

// start the Express server
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});