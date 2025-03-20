import fs from 'fs';
import express, { Request, Response } from "express";
import { cloudProviderJSON } from './util/cloudprovider-utils'
import hostnameRoute from "./routes/hostname";
import infoRoute from "./routes/info";
import allsubnetsRoute from "./routes/allsubnets";
import httpCompression from 'compression';

// create a new express application instance
const app = express();
const PORT = process.env.PORT || 80;
app.use(express.json());
// disable the 'x-powered-by' header in the response
app.disable('x-powered-by');
// enable http compression
app.use(httpCompression());
// define the routes foreach API
app.use("/api/hostname", hostnameRoute);
app.use("/api/info", infoRoute);
app.use("/api/subnets", allsubnetsRoute);
// static URL for favicon
app.use('/favicon.ico', express.static('./release/images/favicon.ico'));

// handle requests for the root URL
app.get("/", (req: Request, res: Response) => {
  var html: string = fs.readFileSync('./release/html/search.html', 'utf-8');
  res.send(html);
});

// start the Express server
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});